 

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

pragma solidity ^0.5.0;


 
contract Pausable is PauserRole {
     
    event Paused(address account);

     
    event Unpaused(address account);

    bool private _paused;

     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

pragma solidity ^0.5.0;


 
contract WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(msg.sender);
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(msg.sender), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(msg.sender);
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

 

pragma solidity 0.5.0;



contract CrowdliKYCProvider is Pausable, WhitelistAdminRole {

	 
	enum VerificationTier { None, KYCAccepted, VideoVerified, ExternalTokenAgent } 
    
     
	mapping (uint => uint) public maxTokenAmountPerTier; 
    
     
    mapping (address => VerificationTier) public verificationTiers;

     
    event LogKYCConfirmation(address indexed sender, VerificationTier verificationTier);

	 
    constructor(address _kycConfirmer, uint _maxTokenForKYCAcceptedTier, uint _maxTokensForVideoVerifiedTier, uint _maxTokensForExternalTokenAgent) public {
        addWhitelistAdmin(_kycConfirmer);
         
        maxTokenAmountPerTier[uint(VerificationTier.None)] = 0;
        
         
        maxTokenAmountPerTier[uint(VerificationTier.KYCAccepted)] = _maxTokenForKYCAcceptedTier;
        
         
        maxTokenAmountPerTier[uint(VerificationTier.VideoVerified)] = _maxTokensForVideoVerifiedTier;
        
         
        maxTokenAmountPerTier[uint(VerificationTier.ExternalTokenAgent)] = _maxTokensForExternalTokenAgent;
    }

    function confirmKYC(address _addressId, VerificationTier _verificationTier) public onlyWhitelistAdmin whenNotPaused {
        emit LogKYCConfirmation(_addressId, _verificationTier);
        verificationTiers[_addressId] = _verificationTier;
    }

    function hasVerificationLevel(address _investor, VerificationTier _verificationTier) public view returns (bool) {
        return (verificationTiers[_investor] == _verificationTier);
    }
    
    function getMaxChfAmountForInvestor(address _investor) public view returns (uint) {
        return maxTokenAmountPerTier[uint(verificationTiers[_investor])];
    }    
}