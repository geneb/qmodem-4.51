uses
  dos, opcrt, opstring;

var
  I: byte;
  fi, fo: text;
  s: string;

begin
  assign(fi, 'test.msg');
  reset(fi);

  assign(fo, 'msg.asm');
  rewrite(fo);

  I := 0;

  while not eof(fi) do begin
    Inc(I);
    readln(fi, S);
    s := trim(s);
    writeln(fo, 'Msg', I, #9, 'DB', #9, length(s), ', '#39, S, #39);
  end;

  close(fo);
  close(fi);
end.

