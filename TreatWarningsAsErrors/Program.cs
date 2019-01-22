using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Xml.Linq;

namespace TreatWarningsAsErrors
{
    class Program
    {
        static void Main(string[] args)
        {
            bool remove = args.Contains("-remove");
            bool dryrun = args.Contains("-dryrun");

            UpdateProjects(remove, dryrun);
        }

        static void UpdateProjects(bool remove, bool dryrun)
        {
            string[] files = Directory.GetFiles(".", "*.*proj", SearchOption.AllDirectories)
                .Select(f => f.StartsWith(@".\") ? f.Substring(2) : f)
                .ToArray();
            Log($"Found {files.Length} projects.");

            foreach (string filename in files)
            {
                Log($"Reading: '{filename}'");
                XDocument xdoc = XDocument.Load(filename);

                bool modified = false;

                XNamespace ns = xdoc.Root.Name.Namespace;

                var propertyGroups = xdoc.Root.Elements(ns + "PropertyGroup");

                if (remove)
                {
                    foreach (var propertyGroup in propertyGroups)
                    {
                        var treatWarningsAsErrorsElements = propertyGroup.Elements(ns + "TreatWarningsAsErrors").ToArray();

                        foreach (var treatWarningsAsErrorsElement in treatWarningsAsErrorsElements)
                        {
                            treatWarningsAsErrorsElement.Remove();
                            modified = true;
                        }
                    }
                }
                else
                {
                    foreach (var propertyGroup in propertyGroups)
                    {
                        var treatWarningsAsErrorsElements = propertyGroup.Elements(ns + "TreatWarningsAsErrors").ToArray();

                        foreach (var treatWarningsAsErrorsElement in treatWarningsAsErrorsElements)
                        {
                            if (treatWarningsAsErrorsElement.Value != "true")
                            {
                                treatWarningsAsErrorsElement.Value = "true";
                                modified = true;
                            }
                        }

                        if (treatWarningsAsErrorsElements.Length == 0)
                        {
                            propertyGroup.Add(new XElement(ns + "TreatWarningsAsErrors", "true"));
                            modified = true;
                        }
                    }
                }

                if (modified)
                {
                    Log($"Saving: '{filename}'");
                    if (dryrun)
                    {
                        Log("NOT!");
                    }
                    else
                    {
                        xdoc.Save(filename);
                    }
                }
            }
        }

        static void Log(string message)
        {
            Console.WriteLine(message);
        }
    }
}
