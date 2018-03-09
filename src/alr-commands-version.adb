with Alire.Properties;

with Alr.Files;
with Alr.Hardcoded;
with Alr.OS;
with Alr.OS_Lib;
with Alr.Session;

with GNAT.Compiler_Version;
with GNAT.Source_Info;

package body Alr.Commands.Version is

   package GNAT_Version is new GNAT.Compiler_Version;

   -------------
   -- Execute --
   -------------

   overriding procedure Execute (Cmd : in out Command) is
      pragma Unreferenced (Cmd);
      use Ada.Text_IO;
   begin
      if Root_Release.Is_Empty then
         Trace.Always ("alr internal project is empty");
      else
         Trace.Always ("alr internal project is " & Root_Release.Current.Milestone.Image);
      end if;

      Trace.Always ("alr session hash is " & Session.Hash);

      declare
         Guard : constant Folder_Guard := Enter_Project_Folder with Unreferenced;
      begin
         Trace.Always ("alr project root detection has settled on path: " & OS_Lib.Current_Folder);
         Trace.Always ("alr is finding" & Files.Locate_Any_GPR_File'Img & " GPR project files");
         Trace.Always ("alr session state is " & Session_State'Img);
         if Session_State >= Outdated then
            if Session_State = Valid then
               Trace.Always ("alr internal session hash matches that of " & Files.Locate_Any_Index_File);
            else
               if Root_Release.Is_Empty then
                  Trace.Always ("alr candidate metadata file in sight: " & Files.Locate_Any_Index_File);
               else
                  Trace.Always ("alr metadata (unmatched hash) file in sight: " & Files.Locate_Any_Index_File);
               end if;
            end if;
         else
            Trace.Always ("alr is not running in a session");
         end if;
      end;

      Log ("alr executable launched from " & OS.Own_Executable, Always);
      Log ("alr rolling source folder is " & Hardcoded.Alr_Src_Folder, Always);

      Log ("alr compiled on [" &
             GNAT.Source_Info.Compilation_ISO_Date & " " &
             GNAT.Source_Info.Compilation_Time & "] with GNAT version [" & GNAT_Version.Version & "]",
           Always);

      -- FIXME this is OS dependent
      declare
         Guard : constant Folder_Guard := OS_Lib.Enter_Folder (Hardcoded.Alr_Src_Folder)
           with Unreferenced;
      begin
         OS_Lib.Spawn_Raw (Hardcoded.Scripts_Version);
      end;

      Trace.Always ("platform fingerprint: " & OS.Fingerprint);
      Put ("platform properties:");
      for Prop of OS.Properties loop
         Put (" " & Prop.Image);
      end loop;
      New_Line;
   end Execute;

end Alr.Commands.Version;
