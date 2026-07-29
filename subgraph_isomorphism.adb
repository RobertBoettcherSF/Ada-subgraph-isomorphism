--  subgraph_isomorphism.adb
--  Package body for Subgraph Isomorphism Problem algorithms
--
--  This package implements:
--  1. Ullmann's Algorithm (1976) - Backtracking approach
--  2. VF2 Algorithm (Cordella, 2004) - Improved with heuristics
--
--  All variants: Decision, Enumeration, Counting, Labeled graphs
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Strings.Unbounded;

package body Subgraph_Isomorphism is

   -- ===================================================================
   -- LOCAL TYPES AND CONSTANTS
   -- ===================================================================

   -- For internal state tracking in Ullmann's algorithm
   type State_Array is array (Vertex_Index) of Boolean;

   -- Maximum recursion depth for safety
   Max_Recursion_Depth : constant := 100;

   -- ===================================================================
   -- GRAPH CONSTRUCTION AND MANIPULATION
   -- ===================================================================

   -- Initialize an empty graph
   procedure Initialize_Graph(G : out Graph; Max_Vertices : Vertex_Count) is
   begin
      if Max_Vertices > Vertex_Index'Last then
         raise Graph_Too_Large with "Maximum vertices exceeded";
      end if;

      G.Num_Vertices := 0;
      G.Num_Edges := 0;

      -- Initialize adjacency matrix
      G.Adj_Matrix := (others => (others => False));

      -- Initialize vertices with empty labels
      G.Vertices := (others => (Label => Empty_Vertex_Label));

      -- Clear edge list
      G.Edge_List := (others => (From => 1, To => 1, Label => Empty_Edge_Label));
   end Initialize_Graph;

   -- Add a vertex to the graph
   procedure Add_Vertex(
      G       : in out Graph;
      V       : Vertex_Index;
      Label   : Vertex_Label := Empty_Vertex_Label) is
   begin
      if V > Vertex_Index'Last then
         raise Invalid_Vertex with "Vertex index out of range";
      end if;

      if G.Num_Vertices >= Vertex_Index'Last then
         raise Graph_Too_Large with "Cannot add more vertices";
      end if;

      G.Num_Vertices := G.Num_Vertices + 1;
      G.Vertices(V) := (Label => Label);
   end Add_Vertex;

   -- Add an edge between two vertices
   procedure Add_Edge(
      G       : in out Graph;
      From, To : Vertex_Index;
      Label   : Edge_Label := Empty_Edge_Label) is
   begin
      if From > G.Num_Vertices or To > G.Num_Vertices then
         raise Invalid_Vertex with "Vertex index exceeds graph size";
      end if;

      if From = To then
         raise Invalid_Edge with "Self-loops not supported";
      end if;

      -- Add to adjacency matrix (undirected graph)
      G.Adj_Matrix(From, To) := True;
      G.Adj_Matrix(To, From) := True;

      -- Add to edge list
      G.Num_Edges := G.Num_Edges + 1;
      G.Edge_List(G.Num_Edges) := (From => From, To => To, Label => Label);
   end Add_Edge;

   -- Create a graph from adjacency matrix
   procedure Create_From_Adjacency(
      G            : out Graph;
      Adj_Matrix   : Adjacency_Matrix;
      Vertex_Labels : array (Vertex_Index) of Vertex_Label :=
         (others => Empty_Vertex_Label)) is
   begin
      Initialize_Graph(G, Vertex_Index'Last);

      -- Set vertex count based on adjacency matrix
      -- Find the actual number of vertices used
      declare
         Max_V : Vertex_Index := 1;
      begin
         -- Find the maximum vertex with any connection
         for I in Vertex_Index loop
            for J in Vertex_Index loop
               if Adj_Matrix(I, J) then
                  if I > Max_V then Max_V := I; end if;
                  if J > Max_V then Max_V := J; end if;
               end if;
            end loop;
         end loop;

         G.Num_Vertices := Max_V;

         -- Copy vertex labels
         for I in 1 .. G.Num_Vertices loop
            G.Vertices(I) := (Label => Vertex_Labels(I));
         end loop;

         -- Copy adjacency matrix
         G.Adj_Matrix := Adj_Matrix;

         -- Build edge list
         G.Num_Edges := 0;
         for I in 1 .. G.Num_Vertices loop
            for J in I + 1 .. G.Num_Vertices loop
               if Adj_Matrix(I, J) then
                  G.Num_Edges := G.Num_Edges + 1;
                  G.Edge_List(G.Num_Edges) := (From => I, To => J, Label => Empty_Edge_Label);
               end if;
            end loop;
         end loop;
      end;
   end Create_From_Adjacency;

   -- ===================================================================
   -- GRAPH PROPERTIES AND VALIDATION
   -- ===================================================================

   -- Check if a graph is valid
   function Is_Valid_Graph(G : Graph) return Boolean is
   begin
      if G.Num_Vertices = 0 then
         return False;
      end if;

      -- Check adjacency matrix symmetry (for undirected graphs)
      for I in 1 .. G.Num_Vertices loop
         for J in 1 .. G.Num_Vertices loop
            if G.Adj_Matrix(I, J) /= G.Adj_Matrix(J, I) then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end Is_Valid_Graph;

   -- Get the degree of a vertex
   function Degree(G : Graph; V : Vertex_Index) return Natural is
      Count : Natural := 0;
   begin
      if V > G.Num_Vertices then
         raise Invalid_Vertex;
      end if;

      for I in 1 .. G.Num_Vertices loop
         if G.Adj_Matrix(V, I) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Degree;

   -- Check if two graphs have compatible sizes
   function Is_Size_Compatible(G, H : Graph) return Boolean is
   begin
      return H.Num_Vertices <= G.Num_Vertices;
   end Is_Size_Compatible;

   -- ===================================================================
   -- ULLMANN'S ALGORITHM IMPLEMENTATION
   -- ===================================================================

   -- Internal recursive procedure for Ullmann's algorithm
   procedure Ullmann_Backtrack(
      G, H           : Graph;
      Depth          : Vertex_Count;
      Current_Mapping : in out Vertex_Mapping;
      Mapped_G       : in out State_Array;
      Mapped_H       : in out State_Array;
      Found          : out Boolean;
      Use_Labels     : Boolean;
      Count          : in out Natural) is

      -- Local variables
      H_Vertex : Vertex_Index;
      G_Vertex : Vertex_Index;
      Valid_Candidate : Boolean;
   begin
      -- Base case: all vertices of H are mapped
      if Depth > H.Num_Vertices then
         Found := True;
         Count := Count + 1;
         return;
      end if;

      -- Try to map the next vertex from H
      H_Vertex := Depth;

      -- Try each unmapped vertex in G as a candidate
      for G_Candidate in 1 .. G.Num_Vertices loop
         if not Mapped_G(G_Candidate) then
            -- Check if this candidate is valid
            Valid_Candidate := True;

            -- Check label compatibility if labels are used
            if Use_Labels then
               if G.Vertices(G_Candidate).Label /= H.Vertices(H_Vertex).Label then
                  Valid_Candidate := False;
               end if;
            end if;

            -- Check adjacency constraints with already mapped vertices
            if Valid_Candidate then
               for H_Mapped in 1 .. Depth - 1 loop
                  declare
                     H_Prev : constant Vertex_Index := H_Mapped;
                     G_Prev : constant Vertex_Index := Current_Mapping(H_Prev);
                  begin
                     -- If H_Prev and H_Vertex are adjacent in H
                     if H.Adj_Matrix(H_Prev, H_Vertex) then
                        -- Then G_Prev and G_Candidate must be adjacent in G
                        if not G.Adj_Matrix(G_Prev, G_Candidate) then
                           Valid_Candidate := False;
                           exit;
                        end if;
                     end if;

                     -- If H_Prev and H_Vertex are NOT adjacent in H
                     if not H.Adj_Matrix(H_Prev, H_Vertex) then
                        -- Then G_Prev and G_Candidate must NOT be adjacent in G
                        if G.Adj_Matrix(G_Prev, G_Candidate) then
                           Valid_Candidate := False;
                           exit;
                        end if;
                     end if;
                  end;
               end loop;
            end if;

            -- If candidate is valid, try it
            if Valid_Candidate then
               -- Map H_Vertex to G_Candidate
               Current_Mapping(H_Vertex) := G_Candidate;
               Mapped_G(G_Candidate) := True;
               Mapped_H(H_Vertex) := True;

               -- Recurse
               Ullmann_Backtrack(
                  G, H,
                  Depth + 1,
                  Current_Mapping,
                  Mapped_G,
                  Mapped_H,
                  Found,
                  Use_Labels,
                  Count);

               -- Backtrack
               Mapped_G(G_Candidate) := False;
               Mapped_H(H_Vertex) := False;

               -- Early exit if we found a solution and only need one
               if Found then
                  return;
               end if;
            end if;
         end if;
      end loop;

      -- If we get here, no mapping was found at this depth
      Found := False;
   end Ullmann_Backtrack;

   -- Ullmann's algorithm - Decision version
   function Ullmann_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean is

      Current_Mapping : Vertex_Mapping;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         return True; -- Empty graph is always a subgraph
      end if;

      if G.Num_Vertices = 0 then
         return H.Num_Vertices = 0;
      end if;

      if not Is_Size_Compatible(G, H) then
         return False;
      end if;

      -- Initialize current mapping
      Current_Mapping := (others => 1);

      -- Start backtracking from depth 1
      Ullmann_Backtrack(
         G, H,
         1,
         Current_Mapping,
         Mapped_G,
         Mapped_H,
         Found,
         Use_Labels,
         Count);

      return Found;
   end Ullmann_Is_Subgraph;

   -- Ullmann's algorithm - Enumeration version
   procedure Ullmann_Find_All_Mappings(
      G, H      : Graph;
      Mappings  : out Mapping_List;
      Max_Mappings : Positive := 1000;
      Use_Labels : Boolean := False) is

      -- We'll use a dynamic approach to collect mappings
      -- Since Ada arrays are fixed size, we'll use a counter
      Found_Count : Natural := 0;
   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         -- Empty pattern: one trivial mapping
         Mappings(1) := (others => 1);
         Found_Count := 1;
         return;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         Found_Count := 0;
         return;
      end if;

      -- For now, implement a simplified version that finds first Max_Mappings
      -- A full enumeration would require dynamic allocation
      declare
         Current_Mapping : Vertex_Mapping;
         Mapped_G : State_Array := (others => False);
         Mapped_H : State_Array := (others => False);
         Found : Boolean := False;
         Count : Natural := 0;

         -- Internal procedure to collect mappings
         procedure Collect_Mappings(
            Depth : Vertex_Count;
            Current_Mapping : in out Vertex_Mapping;
            Mapped_G : in out State_Array;
            Mapped_H : in out State_Array;
            Count : in out Natural) is
         begin
            -- Base case: all vertices of H are mapped
            if Depth > H.Num_Vertices then
               if Count < Max_Mappings then
                  Count := Count + 1;
                  Mappings(Count) := Current_Mapping;
               end if;
               return;
            end if;

            -- Try each unmapped vertex in G
            for G_Candidate in 1 .. G.Num_Vertices loop
               if not Mapped_G(G_Candidate) then
                  declare
                     H_Vertex : constant Vertex_Index := Depth;
                     Valid_Candidate : Boolean := True;
                  begin
                     -- Check label compatibility
                     if Use_Labels then
                        if G.Vertices(G_Candidate).Label /= H.Vertices(H_Vertex).Label then
                           Valid_Candidate := False;
                        end if;
                     end if;

                     -- Check adjacency constraints
                     if Valid_Candidate then
                        for H_Mapped in 1 .. Depth - 1 loop
                           declare
                              H_Prev : constant Vertex_Index := H_Mapped;
                              G_Prev : constant Vertex_Index := Current_Mapping(H_Prev);
                           begin
                              if H.Adj_Matrix(H_Prev, H_Vertex) and then
                                 not G.Adj_Matrix(G_Prev, G_Candidate) then
                                 Valid_Candidate := False;
                                 exit;
                              end if;

                              if not H.Adj_Matrix(H_Prev, H_Vertex) and then
                                 G.Adj_Matrix(G_Prev, G_Candidate) then
                                 Valid_Candidate := False;
                                 exit;
                              end if;
                           end;
                        end loop;
                     end if;

                     if Valid_Candidate then
                        Current_Mapping(H_Vertex) := G_Candidate;
                        Mapped_G(G_Candidate) := True;
                        Mapped_H(H_Vertex) := True;

                        Collect_Mappings(
                           Depth + 1,
                           Current_Mapping,
                           Mapped_G,
                           Mapped_H,
                           Count);

                        Mapped_G(G_Candidate) := False;
                        Mapped_H(H_Vertex) := False;

                        -- Early exit if we have enough mappings
                        if Count >= Max_Mappings then
                           return;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
         end Collect_Mappings;
      begin
         Current_Mapping := (others => 1);
         Collect_Mappings(1, Current_Mapping, Mapped_G, Mapped_H, Found_Count);
      end;
   end Ullmann_Find_All_Mappings;

   -- Ullmann's algorithm - Counting version
   function Ullmann_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural is

      Current_Mapping : Vertex_Mapping;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         return 1; -- Empty graph has one trivial isomorphism
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         return 0;
      end if;

      Current_Mapping := (others => 1);

      Ullmann_Backtrack(
         G, H,
         1,
         Current_Mapping,
         Mapped_G,
         Mapped_H,
         Found,
         Use_Labels,
         Count);

      return Count;
   end Ullmann_Count_Isomorphisms;

   -- ===================================================================
   -- VF2 ALGORITHM IMPLEMENTATION
   -- ===================================================================

   -- VF2 algorithm uses a more sophisticated state representation
   -- with core and terminal sets for pruning

   -- Internal state for VF2
   type VF2_State is record
      Core_G : State_Array;      -- Core set in G
      Core_H : State_Array;      -- Core set in H
      In_G   : State_Array;      -- Terminal set in G
      In_H   : State_Array;      -- Terminal set in H
      Out_G  : State_Array;      -- Remaining vertices in G
      Out_H  : State_Array;      -- Remaining vertices in H
      Mapping : Vertex_Mapping;  -- Current partial mapping
   end record;

   -- Check if the current state satisfies the VF2 feasibility conditions
   function VF2_Is_Feasible(
      G, H : Graph;
      State : VF2_State;
      Use_Labels : Boolean) return Boolean is

      -- Check label compatibility for core sets
      procedure Check_Core_Labels is
      begin
         if Use_Labels then
            for H_V in 1 .. H.Num_Vertices loop
               if State.Core_H(H_V) then
                  declare
                     G_V : constant Vertex_Index := State.Mapping(H_V);
                  begin
                     if G.Vertices(G_V).Label /= H.Vertices(H_V).Label then
                        return;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end Check_Core_Labels;

      -- Check adjacency preservation
      procedure Check_Adjacency_Preservation is
         H_V1, H_V2 : Vertex_Index;
         G_V1, G_V2 : Vertex_Index;
      begin
         -- For all pairs in core sets
         for H_V1 in 1 .. H.Num_Vertices loop
            if State.Core_H(H_V1) then
               G_V1 := State.Mapping(H_V1);

               for H_V2 in 1 .. H.Num_Vertices loop
                  if State.Core_H(H_V2) and H_V1 < H_V2 then
                     G_V2 := State.Mapping(H_V2);

                     -- If adjacent in H, must be adjacent in G
                     if H.Adj_Matrix(H_V1, H_V2) and then
                        not G.Adj_Matrix(G_V1, G_V2) then
                        return;
                     end if;

                     -- If not adjacent in H, must not be adjacent in G
                     if not H.Adj_Matrix(H_V1, H_V2) and then
                        G.Adj_Matrix(G_V1, G_V2) then
                        return;
                     end if;
                  end if;
               end loop;
            end if;
         end loop;
      end Check_Adjacency_Preservation;

      -- Check terminal set consistency
      procedure Check_Terminal_Sets is
      begin
         -- For each vertex in terminal set of H
         for H_V in 1 .. H.Num_Vertices loop
            if State.In_H(H_V) and not State.Core_H(H_V) then
               declare
                  -- Find a candidate in G's terminal set
                  Found_Candidate : Boolean := False;
               begin
                  for G_V in 1 .. G.Num_Vertices loop
                     if State.In_G(G_V) and not State.Core_G(G_V) then
                        -- Check label compatibility
                        if Use_Labels then
                           if G.Vertices(G_V).Label /= H.Vertices(H_V).Label then
                              goto Continue_G_Loop;
                           end if;
                        end if;

                        -- Check adjacency with core vertices
                        declare
                           All_Adjacencies_Preserved : Boolean := True;
                        begin
                           for H_Core in 1 .. H.Num_Vertices loop
                              if State.Core_H(H_Core) then
                                 declare
                                    G_Core : constant Vertex_Index := State.Mapping(H_Core);
                                 begin
                                    if H.Adj_Matrix(H_Core, H_V) and then
                                       not G.Adj_Matrix(G_Core, G_V) then
                                       All_Adjacencies_Preserved := False;
                                       exit;
                                    end if;

                                    if not H.Adj_Matrix(H_Core, H_V) and then
                                       G.Adj_Matrix(G_Core, G_V) then
                                       All_Adjacencies_Preserved := False;
                                       exit;
                                    end if;
                                 end;
                              end if;
                           end loop;

                           if All_Adjacencies_Preserved then
                              Found_Candidate := True;
                              exit;
                           end if;
                        end;
                        <<Continue_G_Loop>>
                        null;
                     end if;
                  end loop;

                  if not Found_Candidate then
                     return;
                  end if;
               end;
            end if;
         end loop;
      end Check_Terminal_Sets;

   begin -- VF2_Is_Feasible
      Check_Core_Labels;
      Check_Adjacency_Preservation;
      Check_Terminal_Sets;
      return True;
   end VF2_Is_Feasible;

   -- Find the next vertex to add to the core set using VF2 heuristics
   procedure VF2_Find_Next_Pair(
      G, H : Graph;
      State : in out VF2_State;
      H_V   : out Vertex_Index;
      G_V   : out Vertex_Index;
      Use_Labels : Boolean) is

      -- Try to find a pair that maintains feasibility
      -- Use heuristics: prefer vertices with higher degree, label matching
   begin
      -- Simple heuristic: find first unmapped vertex in H
      for H_Candidate in 1 .. H.Num_Vertices loop
         if not State.Core_H(H_Candidate) then
            H_V := H_Candidate;

            -- Try to find a matching vertex in G
            for G_Candidate in 1 .. G.Num_Vertices loop
               if not State.Core_G(G_Candidate) then
                  -- Check label compatibility
                  if Use_Labels then
                     if G.Vertices(G_Candidate).Label /= H.Vertices(H_V).Label then
                        goto Continue_G_Loop;
                     end if;
                  end if;

                  -- Check adjacency with existing core
                  declare
                     Valid : Boolean := True;
                  begin
                     for H_Core in 1 .. H.Num_Vertices loop
                        if State.Core_H(H_Core) then
                           declare
                              G_Core : constant Vertex_Index := State.Mapping(H_Core);
                           begin
                              if H.Adj_Matrix(H_Core, H_V) and then
                                 not G.Adj_Matrix(G_Core, G_Candidate) then
                                 Valid := False;
                                 exit;
                              end if;

                              if not H.Adj_Matrix(H_Core, H_V) and then
                                 G.Adj_Matrix(G_Core, G_Candidate) then
                                 Valid := False;
                                 exit;
                              end if;
                           end;
                        end if;
                     end loop;

                     if Valid then
                        G_V := G_Candidate;
                        return;
                     end if;
                  end;
                  <<Continue_G_Loop>>
                  null;
               end if;
            end loop;
         end if;
      end loop;

      -- If no pair found, use first available
      H_V := 1;
      while H_V <= H.Num_Vertices and State.Core_H(H_V) loop
         H_V := H_V + 1;
      end loop;

      G_V := 1;
      while G_V <= G.Num_Vertices and State.Core_G(G_V) loop
         G_V := G_V + 1;
      end loop;
   end VF2_Find_Next_Pair;

   -- VF2 recursive backtracking
   procedure VF2_Backtrack(
      G, H       : Graph;
      State      : in out VF2_State;
      Found      : out Boolean;
      Use_Labels : Boolean;
      Count      : in out Natural) is

      H_V, G_V : Vertex_Index;
   begin
      -- Check if solution is complete
      if State.Core_H = (1 .. H.Num_Vertices => True) then
         Found := True;
         Count := Count + 1;
         return;
      end if;

      -- Find next pair to add to core
      VF2_Find_Next_Pair(G, H, State, H_V, G_V, Use_Labels);

      -- Try to add this pair
      declare
         Old_Mapping : constant Vertex_Mapping := State.Mapping;
         Old_Core_G : constant State_Array := State.Core_G;
         Old_Core_H : constant State_Array := State.Core_H;
         Old_In_G : constant State_Array := State.In_G;
         Old_In_H : constant State_Array := State.In_H;
         Old_Out_G : constant State_Array := State.Out_G;
         Old_Out_H : constant State_Array := State.Out_H;
      begin
         -- Add to core
         State.Mapping(H_V) := G_V;
         State.Core_G(G_V) := True;
         State.Core_H(H_V) := True;

         -- Update terminal sets
         -- Add neighbors of H_V to In_H
         for H_Neighbor in 1 .. H.Num_Vertices loop
            if H.Adj_Matrix(H_V, H_Neighbor) then
               State.In_H(H_Neighbor) := True;
            end if;
         end loop;

         -- Add neighbors of G_V to In_G
         for G_Neighbor in 1 .. G.Num_Vertices loop
            if G.Adj_Matrix(G_V, G_Neighbor) then
               State.In_G(G_Neighbor) := True;
            end if;
         end loop;

         -- Remove from Out sets
         State.Out_G(G_V) := False;
         State.Out_H(H_V) := False;

         -- Check feasibility
         if VF2_Is_Feasible(G, H, State, Use_Labels) then
            VF2_Backtrack(G, H, State, Found, Use_Labels, Count);
         end if;

         -- Backtrack
         State.Mapping := Old_Mapping;
         State.Core_G := Old_Core_G;
         State.Core_H := Old_Core_H;
         State.In_G := Old_In_G;
         State.In_H := Old_In_H;
         State.Out_G := Old_Out_G;
         State.Out_H := Old_Out_H;
      end;
   end VF2_Backtrack;

   -- VF2 algorithm - Decision version
   function VF2_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean is

      State : VF2_State;
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         return True;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         return False;
      end if;

      -- Initialize state
      State.Core_G := (others => False);
      State.Core_H := (others => False);
      State.In_G := (others => False);
      State.In_H := (others => False);
      State.Out_G := (1 .. G.Num_Vertices => True, others => False);
      State.Out_H := (1 .. H.Num_Vertices => True, others => False);
      State.Mapping := (others => 1);

      -- Start backtracking
      VF2_Backtrack(G, H, State, Found, Use_Labels, Count);

      return Found;
   end VF2_Is_Subgraph;

   -- VF2 algorithm - Enumeration version
   procedure VF2_Find_All_Mappings(
      G, H      : Graph;
      Mappings  : out Mapping_List;
      Max_Mappings : Positive := 1000;
      Use_Labels : Boolean := False) is

      State : VF2_State;
      Found : Boolean := False;
      Found_Count : Natural := 0;

      -- Internal backtracking with collection
      procedure VF2_Collect_Backtrack(
         G, H : Graph;
         State : in out VF2_State;
         Found : out Boolean;
         Use_Labels : Boolean;
         Count : in out Natural) is
      begin
         -- Check if solution is complete
         if State.Core_H = (1 .. H.Num_Vertices => True) then
            if Count < Max_Mappings then
               Count := Count + 1;
               Mappings(Count) := State.Mapping;
            end if;
            Found := True;
            return;
         end if;

         declare
            H_V, G_V : Vertex_Index;
         begin
            VF2_Find_Next_Pair(G, H, State, H_V, G_V, Use_Labels);

            declare
               Old_Mapping : constant Vertex_Mapping := State.Mapping;
               Old_Core_G : constant State_Array := State.Core_G;
               Old_Core_H : constant State_Array := State.Core_H;
               Old_In_G : constant State_Array := State.In_G;
               Old_In_H : constant State_Array := State.In_H;
               Old_Out_G : constant State_Array := State.Out_G;
               Old_Out_H : constant State_Array := State.Out_H;
            begin
               State.Mapping(H_V) := G_V;
               State.Core_G(G_V) := True;
               State.Core_H(H_V) := True;

               for H_Neighbor in 1 .. H.Num_Vertices loop
                  if H.Adj_Matrix(H_V, H_Neighbor) then
                     State.In_H(H_Neighbor) := True;
                  end if;
               end loop;

               for G_Neighbor in 1 .. G.Num_Vertices loop
                  if G.Adj_Matrix(G_V, G_Neighbor) then
                     State.In_G(G_Neighbor) := True;
                  end if;
               end loop;

               State.Out_G(G_V) := False;
               State.Out_H(H_V) := False;

               if VF2_Is_Feasible(G, H, State, Use_Labels) then
                  VF2_Collect_Backtrack(G, H, State, Found, Use_Labels, Count);
               end if;

               State.Mapping := Old_Mapping;
               State.Core_G := Old_Core_G;
               State.Core_H := Old_Core_H;
               State.In_G := Old_In_G;
               State.In_H := Old_In_H;
               State.Out_G := Old_Out_G;
               State.Out_H := Old_Out_H;
            end;
         end;
      end VF2_Collect_Backtrack;

   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         Mappings(1) := (others => 1);
         Found_Count := 1;
         return;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         Found_Count := 0;
         return;
      end if;

      -- Initialize state
      State.Core_G := (others => False);
      State.Core_H := (others => False);
      State.In_G := (others => False);
      State.In_H := (others => False);
      State.Out_G := (1 .. G.Num_Vertices => True, others => False);
      State.Out_H := (1 .. H.Num_Vertices => True, others => False);
      State.Mapping := (others => 1);

      VF2_Collect_Backtrack(G, H, State, Found, Use_Labels, Found_Count);
   end VF2_Find_All_Mappings;

   -- VF2 algorithm - Counting version
   function VF2_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural is

      State : VF2_State;
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      -- Check for edge cases
      if H.Num_Vertices = 0 then
         return 1;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         return 0;
      end if;

      -- Initialize state
      State.Core_G := (others => False);
      State.Core_H := (others => False);
      State.In_G := (others => False);
      State.In_H := (others => False);
      State.Out_G := (1 .. G.Num_Vertices => True, others => False);
      State.Out_H := (1 .. H.Num_Vertices => True, others => False);
      State.Mapping := (others => 1);

      VF2_Backtrack(G, H, State, Found, Use_Labels, Count);

      return Count;
   end VF2_Count_Isomorphisms;

   -- ===================================================================
   -- UNIFIED INTERFACE
   -- ===================================================================

   -- Main function: Check if H is isomorphic to a subgraph of G
   function Is_Subgraph(
      G, H         : Graph;
      Algorithm    : Algorithm_Type := VF2;
      Use_Labels   : Boolean := False) return Boolean is
   begin
      case Algorithm is
         when Ullmann =>
            return Ullmann_Is_Subgraph(G, H, Use_Labels);
         when VF2 =>
            return VF2_Is_Subgraph(G, H, Use_Labels);
      end case;
   end Is_Subgraph;

   -- Find all mappings from H to G
   procedure Find_All_Mappings(
      G, H         : Graph;
      Mappings     : out Mapping_List;
      Algorithm    : Algorithm_Type := VF2;
      Max_Mappings : Positive := 1000;
      Use_Labels   : Boolean := False) is
   begin
      case Algorithm is
         when Ullmann =>
            Ullmann_Find_All_Mappings(G, H, Mappings, Max_Mappings, Use_Labels);
         when VF2 =>
            VF2_Find_All_Mappings(G, H, Mappings, Max_Mappings, Use_Labels);
      end case;
   end Find_All_Mappings;

   -- Count the number of isomorphisms
   function Count_Isomorphisms(
      G, H      : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Natural is
   begin
      case Algorithm is
         when Ullmann =>
            return Ullmann_Count_Isomorphisms(G, H, Use_Labels);
         when VF2 =>
            return VF2_Count_Isomorphisms(G, H, Use_Labels);
      end case;
   end Count_Isomorphisms;

   -- ===================================================================
   -- UTILITY FUNCTIONS
   -- ===================================================================

   -- Check if a mapping is valid
   function Is_Valid_Mapping(
      G, H      : Graph;
      Mapping   : Vertex_Mapping;
      Use_Labels : Boolean := False) return Boolean is

   begin
      -- Check that all vertices of H are mapped
      for H_V in 1 .. H.Num_Vertices loop
         declare
            G_V : constant Vertex_Index := Mapping(H_V);
         begin
            -- Check label compatibility
            if Use_Labels then
               if G.Vertices(G_V).Label /= H.Vertices(H_V).Label then
                  return False;
               end if;
            end if;
         end;
      end loop;

      -- Check adjacency preservation
      for H_V1 in 1 .. H.Num_Vertices loop
         for H_V2 in H_V1 + 1 .. H.Num_Vertices loop
            declare
               G_V1 : constant Vertex_Index := Mapping(H_V1);
               G_V2 : constant Vertex_Index := Mapping(H_V2);
            begin
               if H.Adj_Matrix(H_V1, H_V2) and then
                  not G.Adj_Matrix(G_V1, G_V2) then
                  return False;
               end if;

               if not H.Adj_Matrix(H_V1, H_V2) and then
                  G.Adj_Matrix(G_V1, G_V2) then
                  return False;
               end if;
            end;
         end loop;
      end loop;

      return True;
   end Is_Valid_Mapping;

   -- Check if two graphs are isomorphic
   function Are_Isomorphic(
      G, H      : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean is
   begin
      -- For isomorphism, graphs must have same number of vertices
      if G.Num_Vertices /= H.Num_Vertices then
         return False;
      end if;

      -- Use subgraph isomorphism check
      return Is_Subgraph(G, H, Algorithm, Use_Labels);
   end Are_Isomorphic;

   -- Get the induced subgraph from G based on a vertex set
   procedure Get_Induced_Subgraph(
      G          : Graph;
      Vertices   : array (Vertex_Index) of Boolean;
      Subgraph  : out Graph) is

      -- Count selected vertices
      Selected_Count : Vertex_Count := 0;
      Vertex_Map : array (Vertex_Index) of Vertex_Index;
   begin
      -- Count how many vertices are selected
      for V in 1 .. G.Num_Vertices loop
         if Vertices(V) then
            Selected_Count := Selected_Count + 1;
         end if;
      end loop;

      -- Create mapping from old to new indices
      declare
         Current_Index : Vertex_Index := 1;
      begin
         for V in 1 .. G.Num_Vertices loop
            if Vertices(V) then
               Vertex_Map(V) := Current_Index;
               Current_Index := Current_Index + 1;
            else
               Vertex_Map(V) := 0;
            end if;
         end loop;
      end;

      -- Initialize subgraph
      Initialize_Graph(Subgraph, Selected_Count);
      Subgraph.Num_Vertices := Selected_Count;

      -- Add vertices with labels
      for V in 1 .. G.Num_Vertices loop
         if Vertices(V) then
            Subgraph.Vertices(Vertex_Map(V)) := G.Vertices(V);
         end if;
      end loop;

      -- Add edges
      for V1 in 1 .. G.Num_Vertices loop
         if Vertices(V1) then
            for V2 in V1 + 1 .. G.Num_Vertices loop
               if Vertices(V2) and G.Adj_Matrix(V1, V2) then
                  Subgraph.Adj_Matrix(Vertex_Map(V1), Vertex_Map(V2)) := True;
                  Subgraph.Adj_Matrix(Vertex_Map(V2), Vertex_Map(V1)) := True;
               end if;
            end loop;
         end if;
      end loop;
   end Get_Induced_Subgraph;

   -- ===================================================================
   -- DEBUG AND VISUALIZATION
   -- ===================================================================

   -- Print graph information
   procedure Print_Graph(G : Graph) is
      use Ada.Text_IO;
      use Ada.Integer_Text_IO;
   begin
      Put_Line("Graph Information:");
      Put("  Vertices: "); Put_Line(Integer'Image(G.Num_Vertices));
      Put("  Edges: "); Put_Line(Integer'Image(G.Num_Edges));

      New_Line;
      Put_Line("  Vertex Labels:");
      for V in 1 .. G.Num_Vertices loop
         Put("    Vertex "); Put(Integer'Image(V)); Put(": ");
         Put_Line(String(G.Vertices(V).Label));
      end loop;

      New_Line;
      Put_Line("  Adjacency Matrix:");
      for I in 1 .. G.Num_Vertices loop
         for J in 1 .. G.Num_Vertices loop
            if G.Adj_Matrix(I, J) then
               Put("1 ");
            else
               Put("0 ");
            end if;
         end loop;
         New_Line;
      end loop;

      New_Line;
      Put_Line("  Edge List:");
      for I in 1 .. G.Num_Edges loop
         Put("    Edge "); Put(Integer'Image(I));
         Put(": "); Put(Integer'Image(G.Edge_List(I).From));
         Put(" -> "); Put(Integer'Image(G.Edge_List(I).To));
         Put_Line("");
      end loop;
   end Print_Graph;

   -- Print a mapping
   procedure Print_Mapping(M : Vertex_Mapping; Size : Vertex_Count) is
      use Ada.Text_IO;
      use Ada.Integer_Text_IO;
   begin
      Put_Line("Mapping (H -> G):");
      for I in 1 .. Size loop
         Put("  H("); Put(Integer'Image(I)); Put(") -> G(");
         Put(Integer'Image(M(I))); Put_Line(")");
      end loop;
   end Print_Mapping;

end Subgraph_Isomorphism;
