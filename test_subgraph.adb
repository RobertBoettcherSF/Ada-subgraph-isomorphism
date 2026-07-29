--  test_subgraph.adb
--  Test program for Subgraph Isomorphism package
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Subgraph_Isomorphism;
with Ada.Text_IO;
with Ada.Integer_Text_IO;

procedure Test_Subgraph is
   use Subgraph_Isomorphism;
   use Ada.Text_IO;
   use Ada.Integer_Text_IO;

   G, H : Graph;
   Result : Boolean;
   Count : Natural;
   Mappings : Mapping_List;
   Found_Count : Natural;

   -- Test case 1: Simple triangle in a square
   procedure Test_Triangle_In_Square is
   begin
      New_Line;
      Put_Line("=== Test 1: Triangle in Square ===");

      -- Create graph G (square: 4 vertices, 4 edges)
      Initialize_Graph(G, 4);
      Add_Vertex(G, 1);
      Add_Vertex(G, 2);
      Add_Vertex(G, 3);
      Add_Vertex(G, 4);
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 3);
      Add_Edge(G, 3, 4);
      Add_Edge(G, 4, 1);

      -- Create graph H (triangle: 3 vertices, 3 edges)
      Initialize_Graph(H, 3);
      Add_Vertex(H, 1);
      Add_Vertex(H, 2);
      Add_Vertex(H, 3);
      Add_Edge(H, 1, 2);
      Add_Edge(H, 2, 3);
      Add_Edge(H, 3, 1);

      Result := Ullmann_Is_Subgraph(G, H);
      Put("Ullmann: Triangle in Square: "); Put_Line(Boolean'Image(Result));

      Result := VF2_Is_Subgraph(G, H);
      Put("VF2: Triangle in Square: "); Put_Line(Boolean'Image(Result));

      Count := VF2_Count_Isomorphisms(G, H);
      Put("Number of isomorphisms: "); Put_Line(Integer'Image(Count));

      Find_All_Mappings(G, H, Mappings, 10, VF2, Found_Count);
      Put("Found "); Put(Integer'Image(Found_Count)); Put_Line(" mappings");
   end Test_Triangle_In_Square;

   -- Test case 2: Path graph in larger graph
   procedure Test_Path_Graph is
   begin
      New_Line;
      Put_Line("=== Test 2: Path Graph ===");

      Initialize_Graph(G, 5);
      for I in 1 .. 5 loop
         Add_Vertex(G, I);
      end loop;
      for I in 1 .. 4 loop
         Add_Edge(G, I, I + 1);
      end loop;

      Initialize_Graph(H, 3);
      for I in 1 .. 3 loop
         Add_Vertex(H, I);
      end loop;
      for I in 1 .. 2 loop
         Add_Edge(H, I, I + 1);
      end loop;

      Result := Is_Subgraph(G, H, VF2);
      Put("Path 3 in Path 5: "); Put_Line(Boolean'Image(Result));
   end Test_Path_Graph;

   -- Test case 3: Labeled graphs
   procedure Test_Labeled_Graphs is
   begin
      New_Line;
      Put_Line("=== Test 3: Labeled Graphs ===");

      Initialize_Graph(G, 4);
      Add_Vertex(G, 1, "A");
      Add_Vertex(G, 2, "B");
      Add_Vertex(G, 3, "C");
      Add_Vertex(G, 4, "D");
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 3);
      Add_Edge(G, 3, 4);

      Initialize_Graph(H, 3);
      Add_Vertex(H, 1, "A");
      Add_Vertex(H, 2, "B");
      Add_Vertex(H, 3, "C");
      Add_Edge(H, 1, 2);
      Add_Edge(H, 2, 3);

      Result := Is_Subgraph(G, H, VF2, Use_Labels => False);
      Put("Without labels: "); Put_Line(Boolean'Image(Result));

      Result := Is_Subgraph(G, H, VF2, Use_Labels => True);
      Put("With labels: "); Put_Line(Boolean'Image(Result));

      Initialize_Graph(H, 3);
      Add_Vertex(H, 1, "X");
      Add_Vertex(H, 2, "Y");
      Add_Vertex(H, 3, "Z");
      Add_Edge(H, 1, 2);
      Add_Edge(H, 2, 3);

      Result := Is_Subgraph(G, H, VF2, Use_Labels => True);
      Put("With different labels: "); Put_Line(Boolean'Image(Result));
   end Test_Labeled_Graphs;

   -- Test case 4: Empty graphs
   procedure Test_Empty_Graphs is
   begin
      New_Line;
      Put_Line("=== Test 4: Empty Graphs ===");

      Initialize_Graph(G, 3);
      Add_Vertex(G, 1);
      Add_Vertex(G, 2);
      Add_Vertex(G, 3);

      Initialize_Graph(H, 0);

      Result := Is_Subgraph(G, H, VF2);
      Put("Empty H in non-empty G: "); Put_Line(Boolean'Image(Result));

      Initialize_Graph(G, 0);
      Initialize_Graph(H, 1);
      Add_Vertex(H, 1);

      Result := Is_Subgraph(G, H, VF2);
      Put("Non-empty H in empty G: "); Put_Line(Boolean'Image(Result));
   end Test_Empty_Graphs;

   -- Test case 5: Isomorphism (same size)
   procedure Test_Isomorphism is
   begin
      New_Line;
      Put_Line("=== Test 5: Graph Isomorphism ===");

      Initialize_Graph(G, 3);
      for I in 1 .. 3 loop
         Add_Vertex(G, I);
      end loop;
      Add_Edge(G, 1, 2);
      Add_Edge(G, 2, 3);
      Add_Edge(G, 3, 1);

      Initialize_Graph(H, 3);
      for I in 1 .. 3 loop
         Add_Vertex(H, I);
      end loop;
      Add_Edge(H, 1, 2);
      Add_Edge(H, 2, 3);
      Add_Edge(H, 3, 1);

      Result := Are_Isomorphic(G, H, VF2);
      Put("Two triangles are isomorphic: "); Put_Line(Boolean'Image(Result));

      Initialize_Graph(H, 3);
      for I in 1 .. 3 loop
         Add_Vertex(H, I);
      end loop;
      Add_Edge(H, 1, 2);
      Add_Edge(H, 2, 3);

      Result := Are_Isomorphic(G, H, VF2);
      Put("Triangle and path are isomorphic: "); Put_Line(Boolean'Image(Result));
   end Test_Isomorphism;

begin
   Put_Line("Subgraph Isomorphism Test Program");
   Put_Line("==================================");

   Test_Triangle_In_Square;
   Test_Path_Graph;
   Test_Labeled_Graphs;
   Test_Empty_Graphs;
   Test_Isomorphism;

   New_Line;
   Put_Line("All tests completed!");
end Test_Subgraph;
