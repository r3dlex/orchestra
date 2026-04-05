#!/usr/bin/env elixir

:cover.start()

for app <- ~w[musician_core musician_auth musician_tools musician_skills musician_memory musician_session musician_plugins orchestra]a do
  coverdata = "cover/#{app}.coverdata"
  if File.exists?(coverdata) do
    :cover.import(String.to_charlist(coverdata))
  end
end

modules = :cover.imported_modules()

app_prefixes = %{
  "musician_core" => "MusicianCore",
  "musician_auth" => "MusicianAuth",
  "musician_tools" => "MusicianTools",
  "musician_skills" => "MusicianSkills",
  "musician_memory" => "MusicianMemory",
  "musician_session" => "MusicianSession",
  "musician_plugins" => "MusicianPlugins",
  "orchestra" => "Orchestra"
}

app_groups = Enum.group_by(modules, fn mod ->
  mod_str = Atom.to_string(mod)
  Enum.find_value(app_prefixes, fn {app, prefix} ->
    if String.starts_with?(mod_str, "Elixir.#{prefix}"), do: app
  end)
end)

app_packages = for {app, mods} <- app_groups, app != nil do
  {total_covered, total_not_covered} = Enum.reduce(mods, {0, 0}, fn mod, {tc, tnc} ->
    {:ok, functions} = :cover.analyse(mod, :coverage)
    {c, n} = Enum.reduce(functions, {0, 0}, fn {_fun, {c1, n1}}, {ac, an} -> {ac + c1, an + n1} end)
    {tc + c, tnc + n}
  end)
  total = total_covered + total_not_covered
  rate = if total > 0, do: total_covered / total, else: 0.0
  prefix = Map.get(app_prefixes, app)
  package_name = "Elixir.#{prefix}"
  IO.puts("  #{app}: #{Float.round(rate*100, 1)}% (#{total_covered}/#{total})")
  {package_name, rate, total_covered, total_not_covered}
end

packages = for {package_name, rate, covered, not_covered} <- app_packages do
  ~s(<package name="#{package_name}" line-rate="#{Float.round(rate, 4)}" branches-covered="#{covered}" branches-uncovered="#{not_covered}" complexity="0">\n  <type name="% All Types" line-rate="#{Float.round(rate, 4)}" branches-covered="#{covered}" branches-uncovered="#{not_covered}" complexity="0"/>\n</package>)
end |> Enum.join("\n")

xml = ~s[<?xml version="1.0" encoding="UTF-8"?>\n<coverage version="5" timestamp="#{:os.system_time(:second)}" privacy="false" merger="coveralls">\n<packages>\n#{packages}\n</packages>\n</coverage>]
File.mkdir_p!("_build/coverage")
File.write!("_build/coverage/coverage.xml", xml)
IO.puts("Generated _build/coverage/coverage.xml with #{length(app_packages)} apps")
