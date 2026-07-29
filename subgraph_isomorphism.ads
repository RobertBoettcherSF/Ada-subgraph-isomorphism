--  subgraph_isomorphism.ads
--  Package specification for Subgraph Isomorphism Problem algorithms
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Ada.Containers.Vectors;

package Subgraph_Isomorphism is

   -- ===================================================================
   -- TYPE DEFINITIONS
   -- ===================================================================

   -- Vertex index type (1-based for user convenience)
   type Vertex_Index is range 1 .. 100;
   type Vertex_Count is range 0 .. Vertex_Index'Last;

   -- Label types for vertices and edges
   type Vertex_Label is new String(1 .. 50);
   type Edge_Label is new String(1 .. 50);

   -- Empty label constants
   Empty_Vertex_Label : constant Vertex_Label := (others => ' ');
   Empty_Edge_Label   : constant Edge_Label := (others => ' ');

   -- Graph representation using adjacency matrix
   type Adjacency_Matrix is array (Vertex_Index, Vertex_Index) of Boolean;

   -- Edge record with label support
   type Edge is record
      From, To : Vertex_Index;
      Label    : Edge_Label;
   end record;

   -- Vertex record with label
   type Vertex is record
      Label : Vertex_Label;
   end record;

   -- Maximum sizes for fixed arrays
   Max_Vertices : constant := 100;
   Max_Mappings : constant := 1000;

   -- Fixed-size mapping type
   type Vertex_Mapping is array (1 .. Max_Vertices) of Vertex_Index;

   -- Fixed-size mapping list
   type Mapping_List is array (1 .. Max_Mappings) of Vertex_Mapping;

   -- Graph type with vertices and edges
   type Graph is record
      Num_Vertices : Vertex_Count := 0;
      Vertices     : array (1 .. Max_Vertices) of Vertex;
      Adj_Matrix   : Adjacency_Matrix;
      Num_Edges    : Vertex_Count := 0;
   end record;

   -- Result types
   type Algorithm_Type is (Ullmann, VF2);

   -- ===================================================================
   -- EXCEPTIONS
   -- ===================================================================

   Graph_Too_Large : exception;
   Invalid_Vertex  : exception;
   Invalid_Edge    : exception;
   No_Vertices     : exception;
   Too_Many_Mappings : exception;

   -- ===================================================================
   -- GRAPH CONSTRUCTION AND MANIPULATION
   -- ===================================================================

   -- Initialize an empty graph
   procedure Initialize_Graph(G : out Graph; Max_Vertices : Vertex_Count);

   -- Add a vertex to the graph
   procedure Add_Vertex(
      G       : in out Graph;
      V       : Vertex_Index;
      Label   : Vertex_Label := Empty_Vertex_Label);

   -- Add an edge between two vertices
   procedure Add_Edge(
      G       : in out Graph;
      From, To : Vertex_Index;
      Label   : Edge_Label := Empty_Edge_Label);

   -- Create a graph from adjacency matrix
   procedure Create_From_Adjacency(
      G            : out Graph;
      Adj_Matrix   : Adjacency_Matrix;
      Vertex_Labels : array (Vertex_Index) of Vertex_Label :=
         (others => Empty_Vertex_Label));

   -- ===================================================================
   -- GRAPH PROPERTIES AND VALIDATION
   -- ===================================================================

   -- Check if a graph is valid
   function Is_Valid_Graph(G : Graph) return Boolean;

   -- Get the degree of a vertex
   function Degree(G : Graph; V : Vertex_Index) return Natural;

   -- Check if two graphs have compatible sizes
   function Is_Size_Compatible(G, H : Graph) return Boolean;

   -- ===================================================================
   -- SUBGRAPH ISOMORPHISM ALGORITHMS
   -- ===================================================================

   -- Ullmann's algorithm - Decision version
   function Ullmann_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   -- Ullmann's algorithm - Enumeration version
   procedure Ullmann_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;

      Found_Count : out Natural);

   -- Ullmann's algorithm - Counting version
   function Ullmann_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   -- VF2 algorithm - Decision version
   function VF2_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   -- VF2 algorithm - Enumeration version
   procedure VF2_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;
      Found_Count : out Natural);

   -- VF2 algorithm - Counting version
   function VF2_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UNIFIED INTERFACE
   -- ===================================================================

   -- Main function: Check if H is isomorphic to a subgraph of G
   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean;

   -- Find all mappings from H to G
   procedure Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;
      Found_Count : out Natural);

   -- Count the number of isomorphisms
   function Count_Isomorphisms(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UTILITY FUNCTIONS
   -- ===================================================================

   -- Check if a mapping is valid
   function Is_Valid_Mapping(
      G, H : Graph;
      Mapping : Vertex_Mapping;
      H_Size : Vertex_Count;
      Use_Labels : Boolean := False) return Boolean;

   -- Check if two graphs are isomorphic
   function Are_Isomorphic(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean;

   -- Get the induced subgraph from G based on a vertex set
   procedure Get_Induced_Subgraph(
      G : Graph;
      Vertices : array (Vertex_Index) of Boolean;
      Subgraph : out Graph);

   -- ===================================================================
   -- DEBUG AND VISUALIZATION
   -- ===================================================================

   -- Print graph information
   procedure Print_Graph(G : Graph);

   -- Print a mapping
   procedure Print_Mapping(M : Vertex_Mapping; Size : Vertex_Count);

end Subgraph_Isomorphism;
