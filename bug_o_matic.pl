use Purple;
use Pidgin;

my @keywords = ( "bug#", "patch#", "aru#" );
my $bug_base_url = "https://bug.oraclecorp.com/pls/bug/webbug_edit.edit_info_top?rptno=";
my $aru_base_url = "http://aru.us.oracle.com:8080/ARU/ViewCheckin/process_form?bug=";

%PLUGIN_INFO = (
	perl_api_version => 2,
	name => "bug-o-matic",
	version => "0.0.1a",
	summary => "Oracle internal only. Plugin to automatically insert BugDB and ARU links in chats.",
	description => "Oracle internal only. Plugin to automatically insert BugDB and ARU links in chats.",
	author => "Ishan Shrivastava <ishan.shrivastava\@oracle.com>",
	url => "http://github.com/ishan-s/bug-o-matic",
	load => "plugin_load",
	unload => "plugin_unload"
);

sub plugin_init {
	return %PLUGIN_INFO;
}

sub plugin_load {
	my $plugin = shift;
	Purple::Prefs::add_none("/plugins/core/bug-o-matic");
	Purple::Debug::info("bug-o-matic", "plugin_load() - bug-o-matic Plugin Loaded.\n");
	$conv_handle = Purple::Conversations::get_handle();
	$data = "";
	Purple::Signal::connect($conv_handle, "receiving-im-msg", $plugin, \&conv_recv_cb, $data);
	Purple::Signal::connect($conv_handle, "sending-im-msg", $plugin, \&conv_send_cb, $data);
	}

sub plugin_unload {
	my $plugin = shift;
	Purple::Debug::info("bug-o-matic", "plugin_unload() - bug-o-matic Plugin Unloaded.\n");
}

sub get_next_keyword_value_loc{
	my ($str, $ind) = @_;
	
	my $nxi = -1;
	my $val;
	
	#TODO: BUG - order of presence of keyword makes the ones following later in the seeded list not being processed
	# if they appear earlier in the msg
	foreach my $i (0 .. $#keywords){
		my $kw = $keywords[$i];
		
		Purple::Debug::info("bug-o-matic", "Checking for ".$kw."\n");
		$nxi = index($str, $kw, $ind);
		if($nxi >= 0){
			if($str =~ /$kw(\s*)(([0-9]*):R12\.(\w+)\.(\w+))/){
				$val = $2;
				
				if(length($1) > 0){
				$val = $val.$1;
				}
			}
			elsif ($str =~ /$kw(\s*)([0-9]*)/i){
				$val = $2;
				
				if(length($1) > 0){
				$val = $val.$1;
				}
			}
			else{
				$val = "";
			}
			return ($nxi, $kw, $val);
		}
	}
	
	return (-1, undef, undef);	

}

sub get_kw_lists{
	my($msg) = @_;
	
	my $msgl = $msg;
	# look for 'bug#'
	my @bug_list = ($msgl =~ m/bug#[0-9]+/ig);
	
	
	# look for 'aru#'
	$msgl = $msg;
	my @aru_list = ($msgl =~ m/aru#[0-9]+:R12\.\w+\.\w+/ig);
	
	$msgl = $msg;
	my @aru_list_2 = ($msgl =~ m/aru#[0-9]+/ig);
	push @aru_list, @aru_list_2;
	
	# look for 'patch#'
	$msgl = $msg;
	my @patch_list = ($msgl =~ m/patch#[0-9]+:R12\.\w+\.\w+/ig);
	
	$msgl = $msg;
	my @patch_list_2 = ($msgl =~ m/patch#[0-9]+/ig);
	
	push @patch_list, @patch_list_2;
	push @aru_list, @patch_list;
	
	return (\@bug_list, \@aru_list);
}

sub add_links_footer{

	my($msg) = @_;
	Purple::Debug::info("bug-o-matic", "add links footer: ".$msg."\n");
	
	my $msgi = $msg;
	my($bugs, $arus) = get_kw_lists($msgi);
	Purple::Debug::info("bug-o-matic", "bugs ".@bugs."\n");
	Purple::Debug::info("bug-o-matic", "arus  ".@arus."\n");
	
	my @urls;
	my @titles;
	# loop through the bugs
	if(scalar(@$bugs)>0){
		Purple::Debug::info("bug-o-matic", "bugs present "."\n");
		for my $bug (@$bugs){
			Purple::Debug::info("bug-o-matic", "now bug ".$bug."\n");
			$val = substr($bug, index($bug, '#')+1);
			push @urls, $bug_base_url.$val;
			push @titles, "Bug ".$val;
		}
	}
	
	# loop through the aru/patces
	if(scalar(@$arus)>0){
	Purple::Debug::info("bug-o-matic", "arus present "."\n");
		for my $aru (@$arus){
		Purple::Debug::info("bug-o-matic", "now aru ".$aru."\n");
			$val = substr($aru, index($aru, '#')+1);
			push @urls, $aru_base_url.$val;
			push @titles, "ARU ".$val;
		}
	}
	
	my $out_msg = $msg;
	if(scalar(@urls)>0){
		$out_msg = $out_msg."\n\n";
		$out_msg = $out_msg."- bug-o-matic:links -";
		for my $i (0 .. $#urls){
			$out_msg = $out_msg."\n".scalar($i+1).". ".$titles[$i].": ".$urls[$i];
		}
	}
	
	return $out_msg;
}

sub check_bugomatic_ran{
	my($msg) = @_;
	return index($msg, "bug-o-matic:links");
}
sub add_links{
	my($msg) = @_;
	
	my ($loc, $kw, $bug)  = get_next_keyword_value_loc($msg, -1);
	while($loc >= 0){
		Purple::Debug::info("bug-o-matic", "We found keyword: ".$kw." at location: ".$loc." followed by value: ".$bug."\n");
		
		# the keyword is a bug
		if($kw eq $keywords[0]){ 
			$out_url = $bug_base_url.$bug;
		}
		else{
		$out_url = $aru_base_url.$bug;
		}
		
		Purple::Debug::info("bug-o-matic", " Link : ".$out_url);
		$nin = $loc + length($kw) + length($bug);
		
		$add_msg = " [ ".$out_url." ] ";
		substr($msg, $nin, 0) = $add_msg;
		
		$nin = $nin + length($add_msg);
		Purple::Debug::info("bug-o-matic", "Now calling get_next_keyword_loc ->".$msg.", ".$nin."\n");
		($loc, $kw, $bug) = get_next_keyword_value_loc($msg, $nin);
		Purple::Debug::info("bug-o-matic", "Got ->".$loc.", ".$kw.", ".$bug."\n");
		
		last if($loc < 0 || !defined($kw));
		
	}
	
	Purple::Debug::info("bug-o-matic", "Final msg: ".$msg."\n");
	
	return $msg;
}

sub conv_send_cb{
	my($account,  $who, $msg) = @_;
	
	Purple::Debug::info("bug-o-matic", "send msg: ".$msg."\n");
	if(check_bugomatic_ran($msg) eq -1){
		$_[2] = add_links_footer($msg);
	}
	
}

sub conv_recv_cb {
	my($account, $who, $msg, $conv, $flags) = @_;	
	Purple::Debug::info("bug-o-matic", "recv msg: ".$msg."\n");
	
	if(check_bugomatic_ran($msg) eq -1){
		$_[2] = add_links_footer($msg);
	}
	
}




