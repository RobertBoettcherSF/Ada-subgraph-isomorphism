--  subgraph_isomorphism.adb
--  Package body for Subgraph Isomorphism Problem algorithms
--
--  Author: Robert Boettcher
--  Date: July 29, 2026

with Ada.Text_IO;
with Ada.Integer_Text_IO;

package body Subgraph_Isomorphism is

   -- ===================================================================
   -- LOCAL TYPES AND CONSTANTS
   -- ===================================================================

   -- For internal state tracking
   type State_Array is array (Vertex_Index) of Boolean;

   -- ===================================================================
   -- GRAPH CONSTRUCTION AND MANIPULATION
   -- ===================================================================

   procedure Initialize_Graph(G : out Graph; Max_Vertices : Vertex_Count) is
   begin
      if Max_Vertices > Max_Vertices then
         raise Graph_Too_Large with "Maximum vertices exceeded";
      end if;

      G.Num_Vertices := 0;
      G.Num_Edges := 0;

      -- Initialize adjacency matrix
      G.Adj_Matrix := (others => (others => False));

      -- Initialize vertices with empty labels
      G.Vertices := (others => (Label => Empty_Vertex_Label));
   end Initialize_Graph;

   procedure Add_Vertex(
      G : in out Graph;
      V : Vertex_Index;
      Label : Vertex_Label := Empty_Vertex_Label) is
   begin
      if V > Max_Vertices then
         raise Invalid_Vertex with "Vertex index out of range";
      end if;

      if G.Num_Vertices >= Max_Vertices then
         raise Graph_Too_Large with "Cannot add more vertices";
      end if;

      G.Num_Vertices := G.Num_Vertices + 1;
      G.Vertices(V) := (Label => Label);
   end Add_Vertex;

   procedure Add_Edge(
      G : in out Graph;
      From, To : Vertex_Index;
      Label : Edge_Label := Empty_Edge_Label) is
   begin
      if From > G.Num_Vertices or To > G.Num_Vertices then
         raise Invalid_Vertex with "Vertex index exceeds graph size";
      end if;

      if From = To then
         raise Invalid_Edge with "Self-loops not supported";
      end if;

      G.Adj_Matrix(From, To) := True;
      G.Adj_Matrix(To, From) := True;
      G.Num_Edges := G.Num_Edges + 1;
   end Add_Edge;

   procedure Create_From_Adjacency(
      G : out Graph;
      Adj_Matrix : Adjacency_Matrix;
      Vertex_Labels : array (Vertex_Index) of Vertex_Label :=
         (others => Empty_Vertex_Label)) is
   begin
      Initialize_Graph(G, Max_Vertices);

      -- Find actual number of vertices
      declare
         Max_V : Vertex_Index := 1;
      begin
         for I in Vertex_Index loop
            for J in Vertex_Index loop
               if Adj_Matrix(I, J) then
                  if I > Max_V then Max_V := I; end if;
                  if J > Max_V then Max_V := J; end if;
               end if;
            end loop;
         end loop;

         G.Num_Vertices := Max_V;

         for I in 1 .. G.Num_Vertices loop
            G.Vertices(I) := (Label => Vertex_Labels(I));
         end loop;

         G.Adj_Matrix := Adj_Matrix;

         G.Num_Edges := 0;
         for I in 1 .. G.Num_Vertices loop
            for J in I + 1 .. G.Num_Vertices loop
               if Adj_Matrix(I, J) then
                  G.Num_Edges := G.Num_Edges + 1;
               end if;
            end loop;
         end loop;
      end;
   end Create_From_Adjacency;

   -- ===================================================================
   -- GRAPH PROPERTIES AND VALIDATION
   -- ===================================================================

   function Is_Valid_Graph(G : Graph) return Boolean is
   begin
      if G.Num_Vertices = 0 then
         return False;
      end if;

      for I in 1 .. G.Num_Vertices loop
         for J in 1 .. G.Num_Vertices loop
            if G.Adj_Matrix(I, J) /= G.Adj_Matrix(J, I) then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end Is_Valid_Graph;

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

   function Is_Size_Compatible(G, H : Graph) return Boolean is
   begin
      return H.Num_Vertices <= G.Num_Vertices;
   end Is_Size_Compatible;

   -- ===================================================================
   -- ULLMANN'S ALGORITHM IMPLEMENTATION
   -- ===================================================================

   procedure Ullmann_Backtrack(
      G, H : Graph;
      Depth : Vertex_Count;
      Current_Mapping : in out Vertex_Mapping;
      Mapped_G : in out State_Array;
      Mapped_H : in out State_Array;
      Found : out Boolean;
      Use_Labels : Boolean;
      Count : in out Natural) is

      H_Vertex : Vertex_Index;
      Valid_Candidate : Boolean;
   begin
      if Depth > H.Num_Vertices then
         Found := True;
         Count := Count + 1;
         return;
      end if;

      H_Vertex := Depth;

      for G_Candidate in 1 .. G.Num_Vertices loop
         if not Mapped_G(G_Candidate) then
            Valid_Candidate := True;

            if Use_Labels then
               if G.Vertices(G_Candidate).Label /= H.Vertices(H_Vertex).Label then
                  Valid_Candidate := False;
               end if;
            end if;

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

               Ullmann_Backtrack(
                  G, H,
                  Depth + 1,
                  Current_Mapping,
                  Mapped_G,
                  Mapped_H,
                  Found,
                  Use_Labels,
                  Count);

               Mapped_G(G_Candidate) := False;
               Mapped_H(H_Vertex) := False;

               if Found then
                  return;
               end if;
            end if;
         end if;
      end loop;

      Found := False;
   end Ullmann_Backtrack;

   function Ullmann_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean is

      Current_Mapping : Vertex_Mapping;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      if H.Num_Vertices = 0 then
         return True;
      end if;

      if G.Num_Vertices = 0 then
         return H.Num_Vertices = 0;
      end if;

      if not Is_Size_Compatible(G, H) then
         return False;
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

      return Found;
   end Ullmann_Is_Subgraph;

   procedure Ullmann_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;
      Found_Count : out Natural) is

      Current_Mapping : Vertex_Mapping;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Local_Count : Natural := 0;

      procedure Collect_Mappings(
         Depth : Vertex_Count;
         Current_Mapping : in out Vertex_Mapping;
         Mapped_G : in out State_Array;
         Mapped_H : in out State_Array;
         Count : in out Natural) is
      begin
         if Depth > H.Num_Vertices then
            if Count < Max_Mappings then
               Count := Count + 1;
               Mappings(Count) := Current_Mapping;
            end if;
            return;
         end if;

         for G_Candidate in 1 .. G.Num_Vertices loop
            if not Mapped_G(G_Candidate) then
               declare
                  H_Vertex : constant Vertex_Index := Depth;
                  Valid_Candidate : Boolean := True;
               begin
                  if Use_Labels then
                     if G.Vertices(G_Candidate).Label /= H.Vertices(H_Vertex).Label then
                        Valid_Candidate := False;
                     end if;
                  end if;

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

                     if Count >= Max_Mappings then
                        return;
                     end if;
                  end if;
               end;
            end if;
         end loop;
      end Collect_Mappings;
   begin
      if H.Num_Vertices = 0 then
         Found_Count := 1;
         Mappings(1) := (others => 1);
         return;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         Found_Count := 0;
         return;
      end if;

      Current_Mapping := (others => 1);
      Collect_Mappings(1, Current_Mapping, Mapped_G, Mapped_H, Local_Count);
      Found_Count := Local_Count;
   end Ullmann_Find_All_Mappings;

   function Ullmann_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural is

      Current_Mapping : Vertex_Mapping;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      if H.Num_Vertices = 0 then
         return 1;
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

   type VF2_State is record
      Core_G : State_Array;
      Core_H : State_Array;
      In_G : State_Array;
      In_H : State_Array;
      Out_G : State_Array;
      Out_H : State_Array;
      Mapping : Vertex_Mapping;
   end record;

   function VF2_Is_Feasible(
      G, H : Graph;
      State : VF2_State;
      Use_Labels : Boolean) return Boolean is
   begin
      -- Check label compatibility for core sets
      if Use_Labels then
         for H_V in 1 .. H.Num_Vertices loop
            if State.Core_H(H_V) then
               declare
                  G_V : constant Vertex_Index := State.Mapping(H_V);
               begin
                  if G.Vertices(G_V).Label /= H.Vertices(H_V).Label then
                     return False;
                  end if;
               end;
            end if;
         end loop;
      end if;

      -- Check adjacency preservation
      for H_V1 in 1 .. H.Num_Vertices loop
         if State.Core_H(H_V1) then
            declare
               G_V1 : constant Vertex_Index := State.Mapping(H_V1);
            begin
               for H_V2 in 1 .. H.Num_Vertices loop
                  if State.Core_H(H_V2) and H_V1 < H_V2 then
                     declare
                        G_V2 : constant Vertex_Index := State.Mapping(H_V2);
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
                  end if;
               end loop;
            end;
         end if;
      end loop;

      return True;
   end VF2_Is_Feasible;

   procedure VF2_Find_Next_Pair(
      G, H : Graph;
      State : in out VF2_State;
      H_V : out Vertex_Index;
      G_V : out Vertex_Index;
      Use_Labels : Boolean) is
   begin
      for H_Candidate in 1 .. H.Num_Vertices loop
         if not State.Core_H(H_Candidate) then
            H_V := H_Candidate;

            for G_Candidate in 1 .. G.Num_Vertices loop
               if not State.Core_G(G_Candidate) then
                  if Use_Labels then
                     if G.Vertices(G_Candidate).Label /= H.Vertices(H_V).Label then
                        goto Continue_G_Loop;
                     end if;
                  end if;

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

      H_V := 1;
      while H_V <= H.Num_Vertices and State.Core_H(H_V) loop
         H_V := H_V + 1;
      end loop;

      G_V := 1;
      while G_V <= G.Num_Vertices and State.Core_G(G_V) loop
         G_V := G_V + 1;
      end loop;
   end VF2_Find_Next_Pair;

   procedure VF2_Backtrack(
      G, H : Graph;
      State : in out VF2_State;
      Found : out Boolean;
      Use_Labels : Boolean;
      Count : in out Natural) is

      H_V, G_V : Vertex_Index;
   begin
      if State.Core_H = (1 .. H.Num_Vertices => True) then
         Found := True;
         Count := Count + 1;
         return;
      end if;

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
            VF2_Backtrack(G, H, State, Found, Use_Labels, Count);
         end if;

         State.Mapping := Old_Mapping;
         State.Core_G := Old_Core_G;
         State.Core_H := Old_Core_H;
         State.In_G := Old_In_G;
         State.In_H := Old_In_H;
         State.Out_G := Old_Out_G;
         State.Out_H := Old_Out_H;
      end;
   end VF2_Backtrack;

   function VF2_Is_Subgraph(
      G, H : Graph;
      Use_Labels : Boolean := False) return Boolean is

      State : VF2_State;
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      if H.Num_Vertices = 0 then
         return True;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         return False;
      end if;

      State.Core_G := (others => False);
      State.Core_H := (others => False);
      State.In_G := (others => False);
      State.In_H := (others => False);
      State.Out_G := (1 .. G.Num_Vertices => True, others => False);
      State.Out_H := (1 .. H.Num_Vertices => True, others => False);
      State.Mapping := (others => 1);

      VF2_Backtrack(G, H, State, Found, Use_Labels, Count);

      return Found;
   end VF2_Is_Subgraph;

   procedure VF2_Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;
      Found_Count : out Natural) is

      State : VF2_State;
      Local_Count : Natural := 0;

      procedure VF2_Collect_Backtrack(
         G, H : Graph;
         State : in out VF2_State;
         Found : out Boolean;
         Use_Labels : Boolean;
         Count : in out Natural) is
      begin
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

      Found : Boolean := False;
   begin
      if H.Num_Vertices = 0 then
         Found_Count := 1;
         Mappings(1) := (others => 1);
         return;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         Found_Count := 0;
         return;
      end if;

      State.Core_G := (others => False);
      State.Core_H := (others => False);
      State.In_G := (others => False);
      State.In_H := (others => False);
      State.Out_G := (1 .. G.Num_Vertices => True, others => False);
      State.Out_H := (1 .. H.Num_Vertices => True, others => False);
      State.Mapping := (others => 1);

      VF2_Collect_Backtrack(G, H, State, Found, Use_Labels, Local_Count);
      Found_Count := Local_Count;
   end VF2_Find_All_Mappings;

   function VF2_Count_Isomorphisms(
      G, H : Graph;
      Use_Labels : Boolean := False) return Natural is

      State : VF2_State;
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      if H.Num_Vertices = 0 then
         return 1;
      end if;

      if G.Num_Vertices = 0 or not Is_Size_Compatible(G, H) then
         return 0;
      end if;

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

   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean is
   begin
      case Algorithm is
         when Ullmann =>
            return Ullmann_Is_Subgraph(G, H, Use_Labels);
         when VF2 =>
            return VF2_Is_Subgraph(G, H, Use_Labels);
      end case;
   end Is_Subgraph;

   procedure Find_All_Mappings(
      G : Graph;
      H : Graph;
      Mappings : out Mapping_List;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive := Max_Mappings;
      Use_Labels : Boolean := False;
      Found_Count : out Natural) is
   begin
      case Algorithm is
         when Ullmann =>
            Ullmann_Find_All_Mappings(G, H, Mappings, Max_Mappings, Use_Labels, Found_Count);
         when VF2 =>
            VF2_Find_All_Mappings(G, H, Mappings, Max_Mappings, Use_Labels, Found_Count);
      end case;
   end Find_All_Mappings;

   function Count_Isomorphisms(
      G, H : Graph;
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

   function Is_Valid_Mapping(
      G, H : Graph;
      Mapping : Vertex_Mapping;
      H_Size : Vertex_Count;
      Use_Labels : Boolean := False) return Boolean is
   begin
      for H_V in 1 .. H_Size loop
         declare
            G_V : constant Vertex_Index := Mapping(H_V);
         begin
            if Use_Labels then
               if G.Vertices(G_V).Label /= H.Vertices(H_V).Label then
                  return False;
               end if;
            end if;
         end;
      end loop;

      for H_V1 in 1 .. H_Size loop
         for H_V2 in H_V1 + 1 .. H_Size loop
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

   function Are_Isomorphic(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2;
      Use_Labels : Boolean := False) return Boolean is
   begin
      if G.Num_Vertices /= H.Num_Vertices then
         return False;
      end if;

      return Is_Subgraph(G, H, Algorithm, Use_Labels);
   end Are_Isomorphic;

   procedure Get_Induced_Subgraph(
      G : Graph;
      Vertices : array (Vertex_Index) of Boolean;
      Subgraph : out Graph) is

      Selected_Count : Vertex_Count := 0;
      Vertex_Map : array (Vertex_Index) of Vertex_Index;
      Current_Index : Vertex_Index := 1;
   begin
      for V in 1 .. G.Num_Vertices loop
         if Vertices(V) then
            Selected_Count := Selected_Count + 1;
         end if;
      end loop;

      for V in 1 .. G.Num_Vertices loop
         if Vertices(V) then
            Vertex_Map(V) := Current_Index;
            Current_Index := Current_Index + 1;
         else
            Vertex_Map(V) := 0;
         end if;
      end loop;

      Initialize_Graph(Subgraph, Selected_Count);
      Subgraph.Num_Vertices := Selected_Count;

      for V in 1 .. G.Num_Vertices loop
         if Vertices(V) then
            Subgraph.Vertices(Vertex_Map(V)) := G.Vertices(V);
         end if;
      end loop;

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
   end Print_Graph;

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
