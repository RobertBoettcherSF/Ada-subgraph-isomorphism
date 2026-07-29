--  subgraph_isomorphism.ads
--  Package specification for Subgraph Isomorphism Problem algorithms
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

package Subgraph_Isomorphism is

   -- ===================================================================
   -- TYPE DEFINITIONS
   -- ===================================================================

   -- Maximum sizes for fixed arrays
   Max_Vertices : constant := 100;
   Max_Mappings_Constant : constant := 1000;

   -- Vertex index type (1-based for user convenience)
   type Vertex_Index is range 1 .. Max_Vertices;
   type Vertex_Count is range 0 .. Vertex_Index'Last;

   -- Label types for vertices and edges
   type Vertex_Label is new String(1 .. 50);
   type Edge_Label is new String(1 .. 50);

   -- Empty label constants
   Empty_Vertex_Label : constant Vertex_Label := (others => ' ');
   Empty_Edge_Label   : constant Edge_Label := (others => ' ');

   -- Named array types
   type Vertex_Array is array (1 .. Max_Vertices) of Vertex_Index;
   type Adjacency_Matrix_Type is array (Vertex_Index, Vertex_Index) of Boolean;
   type Vertex_Mapping_Type is array (1 .. Max_Vertices) of Vertex_Index;
   type Mapping_List_Type is array (1 .. Max_Mappings_Constant) of Vertex_Mapping_Type;

   -- Edge record with label support
   type Edge is record
      From, To : Vertex_Index;
      Label    : Edge_Label;
   end record;

   -- Vertex record with label
   type Vertex is record
      Label : Vertex_Label;
   end record;

   -- Vertex array type
   type Vertex_List is array (1 .. Max_Vertices) of Vertex;

   -- Graph type with vertices and edges
   type Graph is record
      Num_Vertices : Vertex_Count := 0;
      Vertices     : Vertex_List;
      Adj_Matrix   : Adjacency_Matrix_Type;
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

   -- ===================================================================
   -- GRAPH CONSTRUCTION AND MANIPULATION
   -- ===================================================================

   procedure Initialize_Graph(G : out Graph);

   procedure Add_Vertex(
      G       : in out Graph;
      V       : Vertex_Index;
      Label   : Vertex_Label := Empty_Vertex_Label);

   procedure Add_Edge(
      G       : in out Graph;
      From, To : Vertex_Index;
      Label   : Edge_Label := Empty_Edge_Label);

   -- ===================================================================
   -- GRAPH PROPERTIES AND VALIDATION
   -- ===================================================================

   function Is_Valid_Graph(G : Graph) return Boolean;
   function Degree(G : Graph; V : Vertex_Index) return Natural;
   function Is_Size_Compatible(G, H : Graph) return Boolean;

   -- ===================================================================
   -- SUBGRAPH ISOMORPHISM ALGORITHMS
   -- ===================================================================

   function Ullmann_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   procedure Ullmann_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Use_Labels : Boolean := False;
      Found_Count : out Natural);

   function Ullmann_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   function VF2_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   procedure VF2_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Use_Labels : Boolean := False;
      Found_Count : out Natural);

   function VF2_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UNIFIED INTERFACE
   -- ===================================================================

   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean;

   procedure Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List_Type;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive;
      Use_Labels : Boolean := False;
      Found_Count : out Natural);

   function Count_Isomorphisms(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UTILITY FUNCTIONS
   -- ===================================================================

   function Is_Valid_Mapping(
      G, H : Graph;
      Mapping : Vertex_Mapping_Type;
      H_Size : Vertex_Count;
      Use_Labels : Boolean := False) return Boolean;

   function Are_Isomorphic(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean;

   -- ===================================================================
   -- DEBUG
   -- ===================================================================

   procedure Print_Graph(G : Graph);

end Subgraph_Isomorphism;
