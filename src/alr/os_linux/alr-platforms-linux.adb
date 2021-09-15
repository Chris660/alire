with Alire.Platform;
with Alire.OS_Lib.Subprocess;

with Alr.OS_Lib;

package body Alr.Platforms.Linux is

   use Alr.OS_Lib.Paths;

   ------------------
   -- Architecture --
   ------------------

   overriding
   function Architecture (This : Linux_Variant)
                          return Alire.Platforms.Architectures
   is
      Machine : constant String :=

   begin

   exception
      when E : others =>
         Log_Exception (E);
         return Alire.Platforms.Architecture_Unknown;
   end Architecture;

   ------------------
   -- Cache_Folder --
   ------------------

   overriding function Cache_Folder (This : Linux_Variant) return String is
     (OS_Lib.Getenv ("XDG_CACHE_HOME",
                     Default => OS_Lib.Getenv ("HOME") / ".cache" / "alire"));

   -------------------
   -- Config_Folder --
   -------------------

   overriding function Config_Folder (This : Linux_Variant) return String is
     (OS_Lib.Getenv ("XDG_CONFIG_HOME",
                     Default => OS_Lib.Getenv ("HOME") / ".config" / "alire"));

   ------------------
   -- Distribution --
   ------------------

   overriding function Distribution (This : Linux_Variant)
                                     return Alire.Platforms.Distributions
   is (Alire.Platform.Distribution);

end Alr.Platforms.Linux;
