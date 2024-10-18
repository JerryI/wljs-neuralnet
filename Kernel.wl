BeginPackage["JerryI`Notebook`NeuralUtils`", {
    "JerryI`Notebook`Graphics2D`",
    "Notebook`Kernel`PlotlyExtension`",
    "Notebook`Kernel`Inputs`",
    "JerryI`Misc`Events`",
    "JerryI`Misc`Language`",
    "JerryI`Misc`WLJS`Transport`",
    "Notebook`Editor`Boxes`",
    "Notebook`EditorUtils`"
}]

Begin["`Private`"]

(* deferred evaluation. Applies only when a package has been loaded *)
Internal`AddHandler["GetFileEvent",
 If[MatchQ[#, HoldComplete["NeuralNetworks`",_,_] ],
    applyPatch;
    (* TODO: remove this handler!!! *)
 ]&
]

applyPatch := With[{},
  Unprotect[NetTrain];
  SetOptions[NetTrain, TrainingProgressMeasurements -> Automatic, 
    TrainingProgressReporting->Function[assoc, 
        neuralPrinter[AssociationMap[assoc[#]&, {"RoundLoss", "Net", "TimeElapsed","TimeRemaining", "TargetDevice", "LearningRate", "RoundLossList"}]
    ]
  ] ];

    Unprotect[NeuralNetworks`Private`MakeLayerBoxes];
    ClearAll[NeuralNetworks`Private`MakeLayerBoxes];
    Unprotect[LinearLayer];

    LinearLayer /: NeuralNetworks`Private`MakeLayerBoxes[l_LinearLayer] := Module[{above, below},
            above = { 
              {BoxForm`SummaryItem[{"Output dimensions: ", l[["Parameters"]]["OutputDimensions"]}]},
              {BoxForm`SummaryItem[{"Input dimensions: ", l[["Parameters"]]["$InputDimensions"]}]}
            };

            BoxForm`ArrangeSummaryBox[
               LinearLayer, (* head *)
               l,      (* interpretation *)
               None,    (* icon, use None if not needed *)
               (* above and below must be in a format suitable for Grid or Column *)
               above,    (* always shown content *)
               Null (* expandable content. Currently not supported!*)
            ]
        ];  

    NeuralNetworks`Private`MakeLayerBoxes[l_] := With[{keys = Select[Keys[l[[All]]], (Head[l[[#]]] =!= NumericArray && ByteCount[l[[#]]] < 1024)&]}, Module[{above, below},
            above = Table[{
              {BoxForm`SummaryItem[{StringJoin[k, ": "], l[[k]]}]}
            }, {k, keys}];

            BoxForm`ArrangeSummaryBox[
               Head[l], (* head *)
               l,      (* interpretation *)
               None,    (* icon, use None if not needed *)
               (* above and below must be in a format suitable for Grid or Column *)
               above,    (* always shown content *)
               Null (* expandable content. Currently not supported!*)
            ]
        ] ];


        Unprotect[NeuralNetworks`Private`NetChain`makeNetChainBoxes];
        ClearAll[NeuralNetworks`Private`NetChain`makeNetChainBoxes];

        NeuralNetworks`Private`NetChain`makeNetChainBoxes[c_NetChain] :=             BoxForm`ArrangeSummaryBox[
               NetChain, (* head *)
               c,      (* interpretation *)
               None,    (* icon, use None if not needed *)
               (* above and below must be in a format suitable for Grid or Column *)
               {
                 BoxForm`SummaryItem[{"Chain", TableForm[Head /@ c[[All]]]}]
               },    (* always shown content *)
               Null (* expandable content. Currently not supported!*)
            ];

        Unprotect[NeuralNetworks`Private`NetGraph`makeNetGraphBoxes];
        ClearAll[NeuralNetworks`Private`NetGraph`makeNetGraphBoxes];
        
        NeuralNetworks`Private`NetGraph`makeNetGraphBoxes[c_] := With[{msg = Style["We are looking for volunteers to implement NetGraph", Italic, Background->Yellow]},
          MakeBoxes[msg, StandardForm]
        ];            

];

associatedNets = <||>;
neuralPrinter[assoc_Association] := If[!AssociationQ[Global`$EvaluationContext], Null, With[{callId = Hash[Global`$EvaluationContext["ResultCellHash"]]},
  If[KeyExistsQ[associatedNets, callId],
  
    associatedNets[callId][assoc["RoundLossList"], {
        assoc["TimeElapsed"], assoc["TimeRemaining"],
        assoc["RoundLoss"], assoc["LearningRate"]
    }];

    Null;
  ,
    Module[{generator, length, plot, Global`params, cellContent},
      associatedNets[callId] = Function[{data, p}, 
          PlotlyExtendTraces[plot, <|"y" -> {Drop[data, length]}|>, {0}];
          length = Length[data];
          Global`params = p;

          If[p[[2]] < 0.1,
            cellContent = ToString[Style["Complete", Background->LightGreen], StandardForm];
            associatedNets[callId] = Null;
          ];
      ];

      length = Length[assoc["RoundLossList"]];

      Global`params = {
        assoc["TimeElapsed"], assoc["TimeRemaining"],
        assoc["RoundLoss"], assoc["LearningRate"]
      };

      cellContent = ToString[{
        {Style["Target device", 10], Style[assoc["TargetDevice"], Italic, 10]} // Row,
        {{
          TextView[Global`params[[1]] // Offload, "Label"->"Time elapsed", ImageSize->100],
          TextView[Global`params[[2]] // Offload, "Label"->"Time remaining", ImageSize->100]
        },
        {
          TextView[Global`params[[3]] // Offload, "Label"->"Round loss", ImageSize->100],
          TextView[Global`params[[4]] // Offload, "Label"->"Learning rate", ImageSize->100]  
        }} // Grid,
        plot = Plotly[<|
          "y" -> assoc["RoundLossList"],
          "mode" -> "line"
      |>, <|
          "width"->250, "height"->300
        |>]
      } // Column, StandardForm];
    
      EditorView[cellContent // Offload]

    ]
    
  ]
] ];


End[]
EndPackage[]