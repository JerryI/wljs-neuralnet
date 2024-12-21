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
  SetOptions[NetTrain, 
    TrainingProgressReporting->Function[assoc, 
        neuralPrinter[AssociationMap[assoc[#]&, {"RoundLoss", "Net", "TimeElapsed","TimeRemaining", "TargetDevice", "LearningRate", "RoundLossList"}]
    ]
  ] ] // Quiet;

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

    Unprotect[NeuralNetworks`Private`DefineDecoder`MakeEncoderBoxes];
    ClearAll[NeuralNetworks`Private`DefineDecoder`MakeEncoderBoxes];

    NeuralNetworks`Private`DefineEncoder`MakeEncoderBoxes[l_] := With[{keys = Select[Keys[l[[All]]], (Head[l[[#]]] =!= NumericArray && ByteCount[l[[#]]] < 1024)&]}, Module[{above, below},
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

    Unprotect[NeuralNetworks`Private`DefineDecoder`MakeDecoderBoxes];
    ClearAll[NeuralNetworks`Private`DefineDecoder`MakeDecoderBoxes];

    NeuralNetworks`Private`DefineDecoder`MakeDecoderBoxes[l_] := With[{keys = Select[Keys[l[[All]]], (Head[l[[#]]] =!= NumericArray && ByteCount[l[[#]]] < 1024)&]}, Module[{above, below},
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
    Module[{generator, length, plot, System`params, System`cellContent},
      associatedNets[callId] = Function[{data, p}, 
          PlotlyExtendTraces[plot, <|"y" -> {Drop[data, length]}|>, {0}];
          length = Length[data];
          System`params = p;

          If[p[[2]] < 3,
            System`cellContent = ToString[Style["Complete", Background->LightGreen], StandardForm];
            associatedNets[callId] = Null;
          ];
      ];

      length = Length[assoc["RoundLossList"]];

      System`params = {
        assoc["TimeElapsed"], assoc["TimeRemaining"],
        assoc["RoundLoss"], assoc["LearningRate"]
      };

      System`cellContent = ToString[{
        {Style["Target device", 10], Style[assoc["TargetDevice"], Italic, 10]} // Row,
        {{
          TextView[System`params[[1]] // Offload, "Label"->"Time elapsed", ImageSize->100],
          TextView[System`params[[2]] // Offload, "Label"->"Time remaining", ImageSize->100]
        },
        {
          TextView[System`params[[3]] // Offload, "Label"->"Round loss", ImageSize->100],
          TextView[System`params[[4]] // Offload, "Label"->"Learning rate", ImageSize->100]  
        }} // Grid,
        plot = Plotly[<|
          "y" -> assoc["RoundLossList"],
          "mode" -> "line"
      |>, <|
          "width"->250, "height"->300
        |>]
      } // Column, StandardForm];
    
      EditorView[System`cellContent // Offload]

    ]
    
  ]
] ];


End[]
EndPackage[]