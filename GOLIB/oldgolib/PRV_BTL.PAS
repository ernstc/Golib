uses crt,graph,graftool;


type
    TTipoHCA = (FB,SYS);

    HCA_2 = record
       piano: array [0..3] of pointer;
       DimX,
       DimY:integer;
       tipo:TTipoHCA;
    end;


   {$L btl0200.obj}

   procedure  BitBtl_0200(var FromDC,ToDC:HCA_2; da_x1_,da_y1_,a_x1_,a_y1_:integer; DimX,DimY:word);
   far; external;


var XZone:pointer;
    f,t:HCA_2;

    video_dc_2:hca_2;




begin
  InizializzaGrafica(3,16);

  XZone:=Ptr($A000,$4380);  {0,216}

    with video_dc_2 do begin
    piano[0]:=ptr($A000,0);
    piano[1]:=ptr($A000,0);
    piano[2]:=ptr($A000,0);
    piano[3]:=ptr($A000,0);
    DimX:=MaxXResolution;
    DimY:=MaxYResolution;
    tipo:=FB;
  end;


  SetFillStyle(1,15);
  Bar(20,20,200,200);

  setcolor(14);
  line(0,214,179,214);
  line(40,218,219,218);

  readkey;

  BitBtl_0200(video_dc_2,video_dc_2,20,20,40,220,180,180);

  while keypressed do readkey;
  readkey;
end.