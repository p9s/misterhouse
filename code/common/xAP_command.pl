
# Category = xAP

#@ xAP command server for MH.  Will run requested commands and send respond results back.
#@ It also sets the states of any local object items that match, allowing external programs
#@ to control mh items (e.g. multiple mh systems can have mirrored items)


# TODO: probably need to assign a unique id to request so the correct
# response can always be found amongst many concurrent responses (scalability)
# Bruce: Feel free to change the command structure to suit your ideas.
#        Just let me know when you do so I can update my client

$xap_command_external = new xAP_Item('command.external');
if ($state = $xap_command_external->state_now()) {
	my $response;
	my $targets;
	my $explicitTargets;
	$targets = 'xap';
	# append additional targets in xap "targets" if defined--particularly useful for info-oriented commands
	$explicitTargets = $$xap_command_external{'command.external'}{targets};
	$targets = $targets . ",$explicitTargets" if defined($explicitTargets);

	print "s=$state, command=$$xap_command_external{'command.external'}{command}, xap=$xap_command_external\n";
	$response =&process_external_command(
		$$xap_command_external{'command.external'}{command},
		1,
		$xap_command_external,
		$targets);
				# Special error response.  Normal response handled by respond_xap
	if ($response ne 1) {
	        &xAP::send('xAP',
			"command.response",
			'command.response' => {response => '', error => 1});
		# respond with a message indicating failure if xap targets specified
		if (defined($explicitTargets)) {
			&::respond( target=>$explicitTargets,
					text=>"Failure on command: $$xap_command_external{'command.external'}{command}");
		}
	# respond w/ xap "ackmsg" if it is defined--particularly useful for non-info-oriented commands
	# note: the "ackmsg" response here occurs after any implicit responds occuring in process_external_command
	} elsif (defined($$xap_command_external{'command.external'}{ackmsg})) {
		if (defined($explicitTargets)) {
			&::respond( target=>$explicitTargets,
					text=>$$xap_command_external{'command.external'}{ackmsg} );
		} else {
	# assume that the user wanted the ackmsg spoken if no targets are defined
			speak "$$xap_command_external{'command.external'}{ackmsg}";
		}
	}
	$explicitTargets = undef;
        # very important! - must clear out the attribs for command.external as certain xap message components
	# 	are optional and won't clear out old data otherwise
	undef $$xap_command_external{'command.external'};
}

# This gets invoked by Respond, when target=xap
sub respond_xap
{
	my (%parms) = @_;
        &xAP::send('xAP',
		"command.response",
		'command.response' => {response => $parms{text}, error => 0});
}

$xap_command_voice = new xAP_Item('command.voice');
$xap_command_speak = new xAP_Item('command.speak');


# Monitor item state requests

$xap_mhouse_item = new xAP_Item('mhouse.item');
if (state_now $xap_mhouse_item) {
    my $name = $$xap_mhouse_item{'mhouse.item'}{name};
    my $item = &get_object_by_name($name);
    if ($item) {
        my $state  = $$xap_mhouse_item{'mhouse.item'}{state};
        my $set_by = $$xap_mhouse_item{'mhouse.item'}{set_by};
        my $target = $$xap_mhouse_item{'mhouse.item'}{mh_target};
                                # Use set_by xAP to avoid a loop on mirrored mh systems.
                                # Generic_Item set checks for this when sending data out to xAP.
        set $item $state, 'xAP';
        print "xAP item mirrored: name=$name, state=$state, set_by=$set_by target=$target\n" if $Debug{xap_item};
    }
}