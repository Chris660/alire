with Ada.Directories;

with Alire.Config.Edit;
with Alire.Directories;
with Alire.Manifest;
with Alire.Origins;
with Alire.Paths;
with Alire.Properties.Actions;
with Alire.Root;
with Alire.TTY;
with Alire.Warnings;

with SI_Units.Binary;

package body Alire.Shared is

   use Directories.Operators;

   ---------------
   -- Available --
   ---------------

   function Available return Containers.Release_Set is

      Result : Containers.Release_Set;

      ------------
      -- Detect --
      ------------

      procedure Detect (Item : Ada.Directories.Directory_Entry_Type;
                        Stop : in out Boolean)
      is
         use Ada.Directories;
      begin
         Stop := False;
         if Kind (Item) = Directory then
            if Exists (Full_Name (Item) / Paths.Crate_File_Name) then
               Trace.Debug ("Detected shared release at "
                            & TTY.URL (Full_Name (Item)));

               Result.Include
                 (Releases.From_Manifest
                    (File_Name => Full_Name (Item) / Paths.Crate_File_Name,
                     Source    => Manifest.Index,
                     Strict    => True));
            else
               Warnings.Warn_Once ("Unexpected folder in shared crates path: "
                                   & TTY.URL (Full_Name (Item)));
            end if;

         else
            Warnings.Warn_Once ("Unexpected file in shared crates path: "
                                & TTY.URL (Full_Name (Item)));
         end if;
      end Detect;

   begin
      if Ada.Directories.Exists (Install_Path) then
         Directories.Traverse_Tree
           (Start => Install_Path,
            Doing => Detect'Access);
      end if;

      return Result;
   end Available;

   ------------------
   -- Install_Path --
   ------------------

   function Install_Path return String
   is (Config.Edit.Path
       / Paths.Cache_Folder_Inside_Working_Folder
       / Paths.Deps_Folder_Inside_Cache_Folder);

   -----------
   -- Share --
   -----------

   procedure Share (Release : Releases.Release)
   is
      Already_Installed : Boolean := False;
   begin

      --  See if it is a valid installable origin

      if Release.Origin.Kind in Origins.External_Kinds then
         Raise_Checked_Error
           ("Only regular releases can be installed, but the requested release"
            & " has origin of kind " & Release.Origin.Kind'Image);
      end if;

      if not Release.Dependencies.Is_Empty and then
        not Release.On_Platform_Actions
          (Root.Platform_Properties,
           (Properties.Actions.Post_Fetch => True,
            others                        => False)).Is_Empty
      then
         Raise_Checked_Error
           ("Releases with both dependencies and post-fetch actions are not "
            & " yet supported. (Use `"
            & TTY.Terminal ("alr show <crate=version>") & "` to examine "
            & "release properties.)");
      end if;

      --  See if it can be skipped

      if Available.Contains (Release) then
         Trace.Info ("Skipping installation of already available release: "
                      & Release.Milestone.TTY_Image);
         return;
      end if;

      --  Deploy at the install location

      Release.Deploy (Env             => Root.Platform_Properties,
                      Parent_Folder   => Install_Path,
                      Was_There       => Already_Installed,
                      Perform_Actions => True,
                      Create_Manifest => True,
                      Include_Origin  => True);
      --  We need the origin to be included for the release to be recognized as
      --  a binary-origin release.

      if Already_Installed then
         Trace.Warning
           ("Reused previous installation for existing release: "
            & Release.Milestone.TTY_Image);
      end if;

      Put_Info (Release.Milestone.TTY_Image & " installed successfully.");
   end Share;

   ------------
   -- Remove --
   ------------

   procedure Remove
     (Release : Releases.Release;
      Confirm : Boolean := not Utils.User_Input.Not_Interactive)
   is
      type Modular_File_Size is mod 2 ** Ada.Directories.File_Size'Size;

      function Image is new SI_Units.Binary.Image
        (Item        => Modular_File_Size,
         Default_Aft => 1,
         Unit        => "B");

      use Utils.User_Input;
      Path : constant Absolute_Path := Install_Path / Release.Unique_Folder;
   begin
      if not Ada.Directories.Exists (Path) then
         Raise_Checked_Error
           ("Directory slated for removal does not exist: " & TTY.URL (Path));
      end if;

      if not Confirm or else Utils.User_Input.Query
        (Question => "Release " & Release.Milestone.TTY_Image & " is going to "
         & "be removed, freeing "
         & TTY.Emph (Image (Modular_File_Size (Directories.Tree_Size (Path))))
         & ". Do you want to proceed?",
         Valid    => (No | Yes => True, others => False),
         Default  => Yes) = Yes
      then
         Directories.Force_Delete (Path);
         Put_Success
           ("Release " & Release.Milestone.TTY_Image
            & " removed successfully");
      end if;
   end Remove;

   ------------
   -- Remove --
   ------------

   procedure Remove
     (Target : Milestones.Milestone;
      Confirm : Boolean := not Utils.User_Input.Not_Interactive)
   is
      use type Milestones.Milestone;
   begin
      for Release of Available loop
         if Release.Milestone = Target then
            Remove (Release, Confirm);
            return;
         end if;
      end loop;

      Raise_Checked_Error
        ("Requested release is not installed: " & Target.TTY_Image);
   end Remove;

end Alire.Shared;