<!-- JS - InitModules -->
<script>
function InitModules() {
		{% for key, value in pairs(_G.JSS) do %}
		{[value]}
		{% end %}
}
         
$( document ).ready(function() {

    InitModules();
{% if editing == true then %}
    InitMediumToolbarObjects();
    ApplyMediumEditor();
    ApplyHolder();
 {% end %}
 });
 

 </script>