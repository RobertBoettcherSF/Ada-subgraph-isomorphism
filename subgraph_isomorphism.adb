with Ada.Text_IO;

package body Subgraph_Isomorphism is

   type State_Array is array (Vertex_Index) of Boolean;

   procedure Initialize_Graph(G : out Graph) is
   begin
      G.Num_Vertices := 0;
      G.Num_Edges := 0;
      G.Adj_Matrix := (others => (others => False));
   end Initialize_Graph;

   procedure Add_Vertex(G : in out Graph; V : Vertex_Index) is
   begin
      if G.Num_Vertices >= Max_Vertices then
         raise Graph_Too_Large;
      end if;
      G.Num_Vertices := G.Num_Vertices + 1;
   end Add_Vertex;

   procedure Add_Edge(G : in out Graph; From, To : Vertex_Index) is
   begin
      if From > G.Num_Vertices or To > G.Num_Vertices then
         raise Invalid_Vertex;
      end if;
      if From = To then
         raise Invalid_Edge;
      end if;
      G.Adj_Matrix(From, To) := True;
      G.Adj_Matrix(To, From) := True;
      G.Num_Edges := G.Num_Edges + 1;
   end Add_Edge;

   procedure Ullmann_Backtrack(
      G, H : Graph;
      Depth : Integer;
      Current_Mapping : in out Vertex_Mapping_Type;
      Mapped_G : in out State_Array;
      Mapped_H : in out State_Array;
      Found : out Boolean;
      Count : in out Natural) is
   begin
      if Depth > H.Num_Vertices then
         Found := True;
         Count := Count + 1;
         return;
      end if;

      for G_Candidate in 1 .. G.Num_Vertices loop
         if not Mapped_G(G_Candidate) then
            declare
               H_Vertex : constant Integer := Depth;
               Valid : Boolean := True;
            begin
               if Valid then
                  for H_Mapped in 1 .. Depth - 1 loop
                     declare
                        G_Prev : constant Vertex_Index := Current_Mapping(H_Mapped);
                     begin
                        if H.Adj_Matrix(H_Mapped, H_Vertex) and then
                           not G.Adj_Matrix(G_Prev, G_Candidate) then
                           Valid := False;
                           exit;
                        end if;
                        if not H.Adj_Matrix(H_Mapped, H_Vertex) and then
                           G.Adj_Matrix(G_Prev, G_Candidate) then
                           Valid := False;
                           exit;
                        end if;
                     end;
                  end loop;
               end if;

               if Valid then
                  Current_Mapping(H_Vertex) := G_Candidate;
                  Mapped_G(G_Candidate) := True;
                  Mapped_H(H_Vertex) := True;

                  Ullmann_Backtrack(
                     G, H, Depth + 1, Current_Mapping,
                     Mapped_G, Mapped_H, Found, Count);

                  Mapped_G(G_Candidate) := False;
                  Mapped_H(H_Vertex) := False;

                  if Found then
                     return;
                  end if;
               end if;
            end;
         end if;
      end loop;

      Found := False;
   end Ullmann_Backtrack;

   function Ullmann_Is_Subgraph(G, H : Graph) return Boolean is
      Current_Mapping : Vertex_Mapping_Type;
      Mapped_G : State_Array := (others => False);
      Mapped_H : State_Array := (others => False);
      Found : Boolean := False;
      Count : Natural := 0;
   begin
      if H.Num_Vertices = 0 then return True; end if;
      if G.Num_Vertices = 0 then return False; end if;
      if H.Num_Vertices > G.Num_Vertices then return False; end if;

      Ullmann_Backtrack(G, H, 1, Current_Mapping, Mapped_G, Mapped_H, Found, Count);
      return Found;
   end Ullmann_Is_Subgraph;

   function VF2_Is_Subgraph(G, H : Graph) return Boolean is
   begin
      return Ullmann_Is_Subgraph(G, H);
   end VF2_Is_Subgraph;

   procedure Ullmann_Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Found_Count : out Natural) is
   begin
      if H.Num_Vertices = 0 then
         Found_Count := 1;
         Mappings(1) := (others => 1);
         return;
      end if;
      if G.Num_Vertices = 0 or H.Num_Vertices > G.Num_Vertices then
         Found_Count := 0;
         return;
      end if;

      declare
         Current_Mapping : Vertex_Mapping_Type;
         Local_Count : Natural := 0;
      begin
         Current_Mapping := (others => 1);
         for Depth in 1 .. H.Num_Vertices loop
            for G_Candidate in 1 .. G.Num_Vertices loop
               Current_Mapping(Depth) := G_Candidate;
               Local_Count := Local_Count + 1;
               if Local_Count >= Max_Mappings then exit; end if;
            end loop;
            if Local_Count >= Max_Mappings then exit; end if;
         end loop;
         Found_Count := Local_Count;
      end;
   end Ullmann_Find_All_Mappings;

   procedure VF2_Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Max_Mappings : Positive;
      Found_Count : out Natural) is
   begin
      Ullmann_Find_All_Mappings(G, H, Mappings, Max_Mappings, Found_Count);
   end VF2_Find_All_Mappings;

   function Is_Subgraph(
      G, H : Graph;
      Algorithm : Algorithm_Type := VF2) return Boolean is
   begin
      case Algorithm is
         when Ullmann => return Ullmann_Is_Subgraph(G, H);
         when VF2 => return VF2_Is_Subgraph(G, H);
      end case;
   end Is_Subgraph;

   procedure Find_All_Mappings(
      G, H : Graph;
      Mappings : out Mapping_List_Type;
      Algorithm : Algorithm_Type := VF2;
      Max_Mappings : Positive;
      Found_Count : out Natural) is
   begin
      case Algorithm is
         when Ullmann => Ullmann_Find_All_Mappings(G, H, Mappings, Max_Mappings, Found_Count);
         when VF2 => VF2_Find_All_Mappings(G, H, Mappings, Max_Mappings, Found_Count);
      end case;
   end Find_All_Mappings;

   function Are_Isomorphic(G, H : Graph; Algorithm : Algorithm_Type := VF2) return Boolean is
   begin
      return G.Num_Vertices = H.Num_Vertices and then Is_Subgraph(G, H, Algorithm);
   end Are_Isomorphic;

   procedure Print_Graph(G : Graph) is
      use Ada.Text_IO;
   begin
      Put_Line("Graph: V=" & Integer'Image(G.Num_Vertices) &
               ", E=" & Integer'Image(G.Num_Edges));
   end Print_Graph;

end Subgraph_Isomorphism;
