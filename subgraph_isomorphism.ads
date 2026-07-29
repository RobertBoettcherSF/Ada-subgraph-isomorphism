package Subgraph_Isomorphism is

   Max_Vertices : constant := 100;
   Max_Mappings : constant := 1000;

   type Vertex_Index is range 1 .. Max_Vertices;
   type Vertex_Count is range 0 .. Max_Vertices;

   type Adjacency_Matrix_Type is array (Vertex_Index, Vertex_Index) of Boolean;
   type Vertex_Mapping_Type is array (1 .. Max_Vertices) of Vertex_Index;
   type Mapping_List_Type is array (1 .. Max_Mappings) of Vertex_Mapping_Type;

   type Graph is record
      Num_Vertices : Vertex_Count := 0;
      Adj_Matrix   : Adjacency_Matrix_Type;
      Num_Edges    : Vertex_Count := 0;
   end record;

   type Algorithm_Type is (Ullmann, VF2);

   Graph_Too_Large : exception;
   Invalid_Vertex  : exception;
   Invalid_Edge    : exception;

   procedure Initialize_Graph(G : out Graph);
   procedure Add_Vertex(G : in out Graph; V : Vertex_Index);
   procedure Add_Edge(G : in out Graph; From, To : Vertex_Index);

   function Is_Valid_Graph(G : Graph) return Boolean;
   function Degree(G : Graph; V : Vertex_Index) return Natural;
   function Is_Size_Compatible(G, H : Graph) return Boolean;

   function Ullmann_Is_Subgraph(G, H : Graph) return Boolean;
   procedure Ullmann_Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Found_Count : out Natural);

   function VF2_Is_Subgraph(G, H : Graph) return Boolean;
   procedure VF2_Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Found_Count : out Natural);

   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2) return Boolean;

   procedure Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive;
      Found_Count : out Natural);

   function Are_Isomorphic(G, H : Graph; Algorithm : Algorithm_Type := VF2) return Boolean;

   procedure Print_Graph(G : Graph);

end Subgraph_Isomorphism;
