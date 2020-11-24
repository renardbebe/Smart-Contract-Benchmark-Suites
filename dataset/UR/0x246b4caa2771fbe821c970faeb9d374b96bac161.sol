 

contract DSFalseFallback {
    function() returns (bool) {
        return false;
    }
}

contract DSTrueFallback {
    function() returns (bool) {
        return true;
    }
}

contract DSAuthModesEnum {
    enum DSAuthModes {
        Owner,
        Authority
    }
}

contract DSAuthUtils is DSAuthModesEnum {
    function setOwner( DSAuthorized what, address owner ) internal {
        what.updateAuthority( owner, DSAuthModes.Owner );
    }
    function setAuthority( DSAuthorized what, DSAuthority authority ) internal {
        what.updateAuthority( authority, DSAuthModes.Authority );
    }
}
contract DSAuthorizedEvents is DSAuthModesEnum {
    event DSAuthUpdate( address indexed auth, DSAuthModes indexed mode );
}


 
 
contract DSAuthority {
     
     
     
    function canCall( address caller
                    , address callee
                    , bytes4 sig )
             constant
             returns (bool);
}


contract AcceptingAuthority is DSTrueFallback {}
contract RejectingAuthority is DSFalseFallback {}

 
 
contract DSAuthorized is DSAuthModesEnum, DSAuthorizedEvents
{
     
     
     
     
     
     
    DSAuthModes  public _auth_mode;
    DSAuthority  public _authority;

    function DSAuthorized() {
        _authority = DSAuthority(msg.sender);
        _auth_mode = DSAuthModes.Owner;
        DSAuthUpdate( msg.sender, DSAuthModes.Owner );
    }

     
    modifier auth() {
        if( isAuthorized() ) {
            _
        } else {
            throw;
        }
    }
     
    modifier try_auth() {
        if( isAuthorized() ) {
            _
        }
    }

     
     
    function isAuthorized() internal returns (bool is_authorized) {
        if( _auth_mode == DSAuthModes.Owner ) {
            return msg.sender == address(_authority);
        }
        if( _auth_mode == DSAuthModes.Authority ) {  
            return _authority.canCall( msg.sender, address(this), msg.sig );
        }
        throw;
    }

     
     
    function updateAuthority( address new_authority, DSAuthModes mode )
             auth()
    {
        _authority = DSAuthority(new_authority);
        _auth_mode = mode;
        DSAuthUpdate( new_authority, mode );
    }
}






contract DSAuth is DSAuthorized {}  
contract DSAuthUser is DSAuthUtils {}  

contract DSActionStructUser {
    struct Action {
        address target;
        uint value;
        bytes calldata;
         
    }
     
}
 
contract DSBaseActor is DSActionStructUser {
     
    function tryExec(Action a) internal returns (bool call_ret) {
        return a.target.call.value(a.value)(a.calldata);
    }
    function exec(Action a) internal {
        if(!tryExec(a)) {
            throw;
        }
    }
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            throw;
        }
    }
}

contract DSEasyMultisigEvents {
    event MemberAdded(address who);
    event Proposed(uint indexed action_id, bytes calldata);
    event Confirmed(uint indexed action_id, address who);
    event Triggered(uint indexed action_id);
}

 
contract DSEasyMultisig is DSBaseActor
                         , DSEasyMultisigEvents
                         , DSAuthUser
                         , DSAuth
{
     
    uint _required;
     
    uint _member_count;
     
    uint _members_remaining;
     
    uint _expiration;
     
    uint _last_action_id;


    struct action {
        address target;
        bytes calldata;
        uint value;

        uint confirmations;  
        uint expiration;  
        bool triggered;  
    }

    mapping( uint => action ) actions;

     
    mapping( uint => mapping( address => bool ) ) confirmations;
     
     
    mapping( address => bytes ) easy_calldata;
     
    mapping( address => bool ) is_member;

    function DSEasyMultisig( uint required, uint member_count, uint expiration ) {
        _required = required;
        _member_count = member_count;
        _members_remaining = member_count;
        _expiration = expiration;
    }
     
     
     
    function addMember( address who ) auth()
    {
        if( is_member[who] ) {
            throw;
        }
        is_member[who] = true;
        MemberAdded(who);
        _members_remaining--;
        if( _members_remaining == 0 ) {
            updateAuthority( address(0x0), DSAuthModes.Owner );
        }
    }
    function isMember( address who ) constant returns (bool) {
        return is_member[who];
    }

     
    function getInfo()
             constant
             returns ( uint required, uint members, uint expiration, uint last_proposed_action)
    {
        return (_required, _member_count, _expiration, _last_action_id);
    }
     
    function getActionStatus(uint action_id)
             constant
             returns (uint confirmations, uint expiration, bool triggered, address target, uint eth_value)
    {
        var a = actions[action_id];
        return (a.confirmations, a.expiration, a.triggered, a.target, a.value);
    }

     
    function easyPropose( address target, uint value ) returns (uint action_id) {
        return propose( target, easy_calldata[msg.sender], value );
    }
    function() {
        easy_calldata[msg.sender] = msg.data;
    }

     
     
     
    function propose( address target, bytes calldata, uint value )
             returns (uint action_id)
    {
        action memory a;
        a.target = target;
        a.calldata = calldata;
        a.value = value;
        a.expiration = block.timestamp + _expiration;
         
        _last_action_id++;
        actions[_last_action_id] = a;
        Proposed(_last_action_id, calldata);
        return _last_action_id;
    }

     
     
    function confirm( uint action_id ) returns (bool confirmed) {
        if( !is_member[msg.sender] ) {
            throw;
        }
        if( confirmations[action_id][msg.sender] ) {
            throw;
        }
        if( action_id > _last_action_id ) {
            throw;
        }
        var a = actions[action_id];
        if( block.timestamp > a.expiration ) {
            throw;
        }
        if( a.triggered ) {
            throw;
        }
        confirmations[action_id][msg.sender] = true;
        a.confirmations = a.confirmations + 1;
        actions[action_id] = a;
        Confirmed(action_id, msg.sender);
    }

     
     
    function trigger( uint action_id ) {
        var a = actions[action_id];
        if( a.confirmations < _required ) {
            throw;
        }
        if( block.timestamp > a.expiration ) {
            throw;
        }
        if( a.triggered ) {
            throw;
        }
        if( this.balance < a.value ) {
            throw;
        }
        a.triggered = true;
        exec( a.target, a.calldata, a.value );
        actions[action_id] = a;
        Triggered(action_id);
    }
}