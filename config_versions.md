# Braid configuration version history

The Braid configuration file (`.braids.json`) contains a configuration version
number that indicates the format of the configuration file and the Braid
features required by the project.  You'll be directed to this page if you use a
version of Braid that does not support the project's configuration version; see
[the readme](README.md#braid-version-compatibility) for more information about
the versioning scheme.

To get a compatible version of Braid:

1. First check if the project has its own instructions to install and run Braid,
   and if so, follow them instead.
2. Look up the Braid versions corresponding to your current configuration
   version in the table below.
3. Run `gem query --remote --all --exact braid` to get a list of all existing
   versions of Braid, and choose one that is compatible with your configuration
   version (you probably want the newest such version); call it `x.y.z`.
4. Run `gem install braid --version x.y.z` to install the chosen version of
   Braid.
5. Run Braid as `braid _x.y.z_` (that's the chosen version surrounded by literal
   underscores) followed by your desired arguments.

<table border="border">
<tr>
<th>Config. version</th>
<th>Braid versions</th>
<th>Changes since previous</th>
</tr>
<tr>
<td>1</td>
<td>1.1.x</td>
<td>(Various)</td>
</tr>
<tr>
<td>"0"</td>
<td colspan="2">
(Braid versions earlier than 1.1.0 have varying configuration formats and
features and do not have a well-defined compatibility scheme.  Braid 1.1.0 and
newer refer to all of these formats as version "0" and are capable of correctly
upgrading most of them.  We recommend upgrading to Braid 1.1.0 or newer if you
can.)
</td>
</tr>
</table>

<style>
header, section#downloads, .inner > hr {
    display: none;
}
.inner {
    padding-top: 35px;  /* same as header when it is visible */
}
th, td {
    border: 1px solid #6d6d6d;
    padding: 2px;
}
</style>
