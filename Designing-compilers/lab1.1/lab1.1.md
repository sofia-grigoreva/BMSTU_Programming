% Лабораторная работа № 1.1. Раскрутка самоприменимого компилятора
% 10 февраля 2026 г.
% Софья Григорьева, ИУ9-61Б

# Цель работы
Целью данной работы является ознакомление с раскруткой самоприменимых компиляторов на примере модельного компилятора.

# Индивидуальный вариант
Компилятор BeRo. Добавить однострочный комментарий, начинающийся с символа ?. Т. е. суффикс строки программы, расположенный после символа ?, должен считаться комментарием.

# Реализация

Различие между файлами `btpc64.pas` и `btpc64-2.pas`:

```diff
--- btpc64.pas  2026-02-10 16:41:38.000000000 +0300
+++ btpc64-2.pas        2026-02-11 12:46:41.271586345 +0300
@@ -748,10 +748,15 @@
   end else begin
    Error(102);
   end;
+ end else if CurrentChar='?' then begin
+  repeat
+   ReadChar;
+  until (CurrentChar=#10) or (CurrentChar=#0);
+  GetSymbol;
  end else begin
   Error(102);
  end;
-end;
+ end;
 
 procedure Check(s:integer);
 begin
```

Различие между файлами `btpc64-2.pas` и `btpc64-3.pas`:

```diff
--- btpc64-2.pas        2026-02-11 12:46:41.271586345 +0300
+++ btpc64-3.pas        2026-02-10 17:11:28.000000000 +0300
@@ -749,6 +749,7 @@
    Error(102);
   end;
  end else if CurrentChar='?' then begin
+  ReadChar;
   repeat
    ReadChar;
   until (CurrentChar=#10) or (CurrentChar=#0);
@@ -2507,7 +2508,7 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($94); EmitByte($d0); // SETE AL
+    EmitByte($0f); EmitByte($94); EmitByte($d0); ? SETE AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
@@ -2516,7 +2517,7 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($95); EmitByte($d0); // SETNE AL
+    EmitByte($0f); EmitByte($95); EmitByte($d0); ? SETNE AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
@@ -2525,7 +2526,7 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($9c); EmitByte($d0); // SETL AL
+    EmitByte($0f); EmitByte($9c); EmitByte($d0); ? SETL AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
@@ -2534,7 +2535,7 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($9e); EmitByte($d0); // SETLE AL
+    EmitByte($0f); EmitByte($9e); EmitByte($d0); ? SETLE AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
@@ -2543,7 +2544,7 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($9f); EmitByte($d0); // SETG AL
+    EmitByte($0f); EmitByte($9f); EmitByte($d0); ? SETG AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
@@ -2552,13 +2553,13 @@
     OCPopEBX;
     OCPopEAX;
     OCCmpEAXEBX;
-    EmitByte($0f); EmitByte($9d); EmitByte($d0); // SETGE AL
+    EmitByte($0f); EmitByte($9d); EmitByte($d0); ? SETGE AL
     LastOutputCodeValue:=locNone;
     OCMovzxEAXAL;
     OCPushEAX;
    end;
    OPDupl:begin
-    EmitByte($ff); EmitByte($34); EmitByte($24); // PUSH DWORD PTR [ESP]
+    EmitByte($ff); EmitByte($34); EmitByte($24); ? PUSH DWORD PTR [ESP]
     LastOutputCodeValue:=locNone;
    end;
    OPSwap:begin
```

# Тестирование

Тестовый пример:

```pascal
program Hello;

begin
  // комментарий
  ? мой комментарий
  WriteLn('Hello, student!'); ? мой комментарий
end.
```

Вывод тестового примера на `stdout`

```
Hello, student!
```

# Вывод

В ходе работы изучен код компилятора, выполнена его модификация с добавлением нового вида однострочного комментария, освоена раскрутка самоприменимого компилятора, осуществлён её шаг и проверена корректность работы полученной версии.
