--  subgraph_isomorphism.ads
--  Package specification for Subgraph Isomorphism Problem algorithms
--
--  This package implements algorithms for solving the subgraph isomorphism problem:
--  - Ullmann's backtracking algorithm (1976)
--  - VF2 algorithm (Cordella, 2004)
--
--  Variants implemented:
--  1. Decision: Check if H is isomorphic to a subgraph of G (Boolean result)
--  2. Enumeration: Find all mappings (all valid isomorphisms)
--  3. Counting: Count the number of isomorphisms
--  4. Labeled graphs: Support for vertex and edge labels
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings.Unbounded;

package Subgraph_Isomorphism is

   -- ===================================================================
   -- TYPE DEFINITIONS
   -- ===================================================================

   -- Vertex index type (1-based for user convenience)
   type Vertex_Index is range 1 .. 1000;
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

   -- Edge list for sparse representation
   type Edge_List is array (Positive range <>) of Edge;

   -- Vertex record with label
   type Vertex is record
      Label : Vertex_Label;
   end record;

   -- Graph type with vertices and edges
   type Graph is record
      Num_Vertices : Vertex_Count := 0;
      Vertices     : array (Vertex_Index) of Vertex;
      Adj_Matrix   : Adjacency_Matrix;
      Edge_List    : Edge_List(1 .. 1000); -- Sparse edge storage
      Num_Edges    : Vertex_Count := 0;
   end record;

   -- Mapping type: maps vertices from pattern (H) to target (G)
   type Vertex_Mapping is array (Vertex_Index) of Vertex_Index;
   type Mapping_List is array (Positive range <>) of Vertex_Mapping;

   -- Result types
   type Isomorphism_Result is (Found, Not_Found);
   type Solution_Type is (First, All, Count);

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

   -- Check if a graph is valid (no invalid vertex indices)
   function Is_Valid_Graph(G : Graph) return Boolean;

   -- Get the degree of a vertex
   function Degree(G : Graph; V : Vertex_Index) return Natural;

   -- Check if two graphs have compatible sizes for subgraph isomorphism
   function Is_Size_Compatible(G, H : Graph) return Boolean;

   -- ===================================================================
   -- SUBGRAPH ISOMORPHISM ALGORITHMS
   -- ===================================================================

   -- ===================================================================
   -- ULLMANN'S ALGORITHM (1976)
   -- Backtracking algorithm for subgraph isomorphism
   -- ===================================================================

   -- Ullmann's algorithm - Decision version
   -- Returns True if H is isomorphic to a subgraph of G
   function Ullmann_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   -- Ullmann's algorithm - Enumeration version
   -- Returns all mappings from H to G
   procedure Ullmann_Find_All_Mappings(
      G, H      : Graph;
      Mappings  : out Mapping_List;
      Max_Mappings : Positive := 1000;
      Use_Labels : Boolean := False);

   -- Ullmann's algorithm - Counting version
   -- Returns the number of isomorphisms
   function Ullmann_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- VF2 ALGORITHM (Cordella, 2004)
   -- Improved algorithm based on Ullmann's with better heuristics
   -- ===================================================================

   -- VF2 algorithm - Decision version
   function VF2_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean;

   -- VF2 algorithm - Enumeration version
   procedure VF2_Find_All_Mappings(
      G, H      : Graph;
      Mappings  : out Mapping_List;
      Max_Mappings : Positive := 1000;
      Use_Labels : Boolean := False);

   -- VF2 algorithm - Counting version
   function VF2_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UNIFIED INTERFACE
   -- ===================================================================

   -- Generic subgraph isomorphism check with algorithm selection
   type Algorithm_Type is (Ullmann, VF2);

   -- Main function: Check if H is isomorphic to a subgraph of G
   function Is_Subgraph(
      G, H         : Graph;
      Algorithm    : Algorithm_Type := VF2;
      Use_Labels   : Boolean := False) return Boolean;

   -- Find all mappings from H to G
   procedure Find_All_Mappings(
      G, H         : Graph;
      Mappings     : out Mapping_List;
      Algorithm    : Algorithm_Type := VF2;
      Max_Mappings : Positive := 1000;
      Use_Labels   : Boolean := False);

   -- Count the number of isomorphisms
   function Count_Isomorphisms(
      G, H      : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Natural;

   -- ===================================================================
   -- UTILITY FUNCTIONS
   -- ===================================================================

   -- Check if a mapping is valid (preserves adjacency)
   function Is_Valid_Mapping(
      G, H      : Graph;
      Mapping   : Vertex_Mapping;
      Use_Labels : Boolean := False) return Boolean;

   -- Check if two graphs are isomorphic (not just subgraph)
   function Are_Isomorphic(
      G, H      : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean;

   -- Get the induced subgraph from G based on a vertex set
   procedure Get_Induced_Subgraph(
      G          : Graph;
      Vertices   : array (Vertex_Index) of Boolean;
      Subgraph  : out Graph);

   -- ===================================================================
   -- DEBUG AND VISUALIZATION
   -- ===================================================================

   -- Print graph information
   procedure Print_Graph(G : Graph);

   -- Print a mapping
   procedure Print_Mapping(M : Vertex_Mapping; Size : Vertex_Count);

end Subgraph_Isomorphism;
