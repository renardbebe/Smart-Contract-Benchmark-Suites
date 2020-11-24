 

pragma solidity 0.4.15;

 
contract IAccessPolicy {

     
     
     

     
     
     
     
     
     
     
    function allowed(
        address subject,
        bytes32 role,
        address object,
        bytes4 verb
    )
        public
        returns (bool);
}

 
 
contract IAccessControlled {

     
     
     

     
    event LogAccessPolicyChanged(
        address controller,
        IAccessPolicy oldPolicy,
        IAccessPolicy newPolicy
    );

     
     
     

     
     
     
     
     
     
    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public;

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy);

}

contract StandardRoles {

     
     
     

     
     
    bytes32 internal constant ROLE_ACCESS_CONTROLLER = 0xac42f8beb17975ed062dcb80c63e6d203ef1c2c335ced149dc5664cc671cb7da;
}

 
 
 
 
 
 
contract AccessControlled is IAccessControlled, StandardRoles {

     
     
     

    IAccessPolicy private _accessPolicy;

     
     
     

     
    modifier only(bytes32 role) {
        require(_accessPolicy.allowed(msg.sender, role, this, msg.sig));
        _;
    }

     
     
     

    function AccessControlled(IAccessPolicy policy) internal {
        require(address(policy) != 0x0);
        _accessPolicy = policy;
    }

     
     
     

     
     
     

    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
         
         
         
        require(newPolicy.allowed(newAccessController, ROLE_ACCESS_CONTROLLER, this, msg.sig));

         
        IAccessPolicy oldPolicy = _accessPolicy;
        _accessPolicy = newPolicy;

         
        LogAccessPolicyChanged(msg.sender, oldPolicy, newPolicy);
    }

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy)
    {
        return _accessPolicy;
    }
}

contract AccessRoles {

     
     
     

     
     
     

     
    bytes32 internal constant ROLE_LOCKED_ACCOUNT_ADMIN = 0x4675da546d2d92c5b86c4f726a9e61010dce91cccc2491ce6019e78b09d2572e;

     
    bytes32 internal constant ROLE_WHITELIST_ADMIN = 0xaef456e7c864418e1d2a40d996ca4febf3a7e317fe3af5a7ea4dda59033bbe5c;

     
    bytes32 internal constant ROLE_NEUMARK_ISSUER = 0x921c3afa1f1fff707a785f953a1e197bd28c9c50e300424e015953cbf120c06c;

     
    bytes32 internal constant ROLE_NEUMARK_BURNER = 0x19ce331285f41739cd3362a3ec176edffe014311c0f8075834fdd19d6718e69f;

     
    bytes32 internal constant ROLE_SNAPSHOT_CREATOR = 0x08c1785afc57f933523bc52583a72ce9e19b2241354e04dd86f41f887e3d8174;

     
    bytes32 internal constant ROLE_TRANSFER_ADMIN = 0xb6527e944caca3d151b1f94e49ac5e223142694860743e66164720e034ec9b19;

     
    bytes32 internal constant ROLE_RECLAIMER = 0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5;

     
    bytes32 internal constant ROLE_PLATFORM_OPERATOR_REPRESENTATIVE = 0xb2b321377653f655206f71514ff9f150d0822d062a5abcf220d549e1da7999f0;

     
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;
}

contract IBasicToken {

     
     
     

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount);

     
     
     

     
     
    function totalSupply()
        public
        constant
        returns (uint256);

     
     
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance);

     
     
     
     
    function transfer(address to, uint256 amount)
        public
        returns (bool success);

}

 
 
 
 
 
 
 
contract Reclaimable is AccessControlled, AccessRoles {

     
     
     

    IBasicToken constant internal RECLAIM_ETHER = IBasicToken(0x0);

     
     
     

    function reclaim(IBasicToken token)
        public
        only(ROLE_RECLAIMER)
    {
        address reclaimer = msg.sender;
        if(token == RECLAIM_ETHER) {
            reclaimer.transfer(this.balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract RoleBasedAccessPolicy is
    IAccessPolicy,
    AccessControlled,
    Reclaimable
{

     
     
     

     
    enum TriState {
        Unset,
        Allow,
        Deny
    }

     
     
     

    IAccessControlled private constant GLOBAL = IAccessControlled(0x0);

    address private constant EVERYONE = 0x0;

     
     
     

     
    mapping (address =>
        mapping(bytes32 =>
            mapping(address => TriState))) private _access;

     
     
    mapping (address =>
        mapping(bytes32 => address[])) private _accessList;

     
     
     

     
    event LogAccessChanged(
        address controller,
        address indexed subject,
        bytes32 role,
        address indexed object,
        TriState oldValue,
        TriState newValue
    );

    event LogAccess(
        address indexed subject,
        bytes32 role,
        address indexed object,
        bytes4 verb,
        bool granted
    );

     
     
     

    function RoleBasedAccessPolicy()
        AccessControlled(this)  
        public
    {
         
        _access[msg.sender][ROLE_ACCESS_CONTROLLER][this] = TriState.Allow;
        _access[msg.sender][ROLE_ACCESS_CONTROLLER][GLOBAL] = TriState.Allow;
         
        updatePermissionEnumerator(msg.sender, ROLE_ACCESS_CONTROLLER, this, TriState.Unset, TriState.Allow);
        updatePermissionEnumerator(msg.sender, ROLE_ACCESS_CONTROLLER, GLOBAL, TriState.Unset, TriState.Allow);
    }

     
     
     

     
    function setAccessPolicy(IAccessPolicy, address)
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
         
         
         
        revert();
    }

     
    function allowed(
        address subject,
        bytes32 role,
        address object,
        bytes4 verb
    )
        public
         
        returns (bool)
    {
        bool set = false;
        bool allow = false;
        TriState value = TriState.Unset;

         
        value = _access[subject][role][object];
        set = value != TriState.Unset;
        allow = value == TriState.Allow;
        if (!set) {
            value = _access[subject][role][GLOBAL];
            set = value != TriState.Unset;
            allow = value == TriState.Allow;
        }
        if (!set) {
            value = _access[EVERYONE][role][object];
            set = value != TriState.Unset;
            allow = value == TriState.Allow;
        }
        if (!set) {
            value = _access[EVERYONE][role][GLOBAL];
            set = value != TriState.Unset;
            allow = value == TriState.Allow;
        }
         
        if (!set) {
            allow = false;
        }

         
        LogAccess(subject, role, object, verb, allow);
        return allow;
    }

     
    function setUserRole(
        address subject,
        bytes32 role,
        IAccessControlled object,
        TriState newValue
    )
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
        setUserRolePrivate(subject, role, object, newValue);
    }

     
    function setUserRoles(
        address[] subjects,
        bytes32[] roles,
        IAccessControlled[] objects,
        TriState[] newValues
    )
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
        require(subjects.length == roles.length);
        require(subjects.length == objects.length);
        require(subjects.length == newValues.length);
        for(uint256 i = 0; i < subjects.length; ++i) {
            setUserRolePrivate(subjects[i], roles[i], objects[i], newValues[i]);
        }
    }

    function getValue(
        address subject,
        bytes32 role,
        IAccessControlled object
    )
        public
        constant
        returns (TriState)
    {
        return _access[subject][role][object];
    }

    function getUsers(
        IAccessControlled object,
        bytes32 role
    )
        public
        constant
        returns (address[])
    {
        return _accessList[object][role];
    }

     
     
     

    function setUserRolePrivate(
        address subject,
        bytes32 role,
        IAccessControlled object,
        TriState newValue
    )
        private
    {
         
         
         
         
        require(role != ROLE_ACCESS_CONTROLLER || subject != msg.sender || object != this);

         
        TriState oldValue = _access[subject][role][object];
        if(oldValue == newValue) {
            return;
        }

         
        _access[subject][role][object] = newValue;

         
        updatePermissionEnumerator(subject, role, object, oldValue, newValue);

         
        LogAccessChanged(msg.sender, subject, role, object, oldValue, newValue);
    }

    function updatePermissionEnumerator(
        address subject,
        bytes32 role,
        IAccessControlled object,
        TriState oldValue,
        TriState newValue
    )
        private
    {
         
        address[] storage list = _accessList[object][role];
         
        if(oldValue == TriState.Unset && newValue != TriState.Unset) {
            list.push(subject);
        }
         
        if(oldValue != TriState.Unset && newValue == TriState.Unset) {
            for(uint256 i = 0; i < list.length; ++i) {
                if(list[i] == subject) {
                     
                    list[i] = list[list.length - 1];
                    delete list[list.length - 1];
                    list.length -= 1;
                     
                    break;
                }
            }
        }
    }
}