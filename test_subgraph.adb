with Subgraph_Isomorphism;
with Ada.Text_IO;

procedure Test_Subgraph is
   use Subgraph_Isomorphism;
   use Ada.Text_IO;

   G, H : Graph;
   Result : Boolean;
   Count : Natural;
   Mappings : Mapping_List_Type;
   Found_Count : Natural;

begin
   Put_Line("Subgraph Isomorphism Test Program");
   Put_Line("==================================");

   -- Test 1: Triangle in Square
   New_Line;
   Put_Line("Test 1: Triangle in Square");
   Initialize_Graph(G);
   Add_Vertex(G, 1);
   Add_Vertex(G, 2);
   Add_Vertex(G, 3);
   Add_Vertex(G, 4);
   Add_Edge(G, 1, 2);
   Add_Edge(G, 2, 3);
   Add_Edge(G, 3, 4);
   Add_Edge(G, 4, 1);

   Initialize_Graph(H);
   Add_Vertex(H, 1);
   Add_Vertex(H, 2);
   Add_Vertex(H, 3);
   Add_Edge(H, 1, 2);
   Add_Edge(H, 2, 3);
   Add_Edge(H, 3, 1);

   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Triangle in Square: " & Boolean'Image(Result));

   -- Test 2: Path
   New_Line;
   Put_Line("Test 2: Path Graph");
   Initialize_Graph(G);
   Add_Vertex(G, 1);
   Add_Vertex(G, 2);
   Add_Vertex(G, 3);
   Add_Edge(G, 1, 2);
   Add_Edge(G, 2, 3);

   Initialize_Graph(H);
   Add_Vertex(H, 1);
   Add_Vertex(H, 2);
   Add_Edge(H, 1, 2);

   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Path 2 in Path 3: " & Boolean'Image(Result));

   -- Test 3: Empty
   New_Line;
   Put_Line("Test 3: Empty Graphs");
   Initialize_Graph(G);
   Initialize_Graph(H);
   Result := Is_Subgraph(G, H, VF2);
   Put_Line("Empty H in empty G: " & Boolean'Image(Result));

   Put_Line("All tests completed!");
end Test_Subgraph;
