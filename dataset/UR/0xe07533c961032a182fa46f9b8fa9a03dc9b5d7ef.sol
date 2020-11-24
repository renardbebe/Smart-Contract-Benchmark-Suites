 

pragma solidity ^0.5.0;

pragma experimental ABIEncoderV2;


library FixedPoint {

    using SafeMath for uint;

     
     
    uint private constant FP_SCALING_FACTOR = 10**18;

    struct Unsigned {
        uint rawValue;
    }

     
    function fromUnscaledUint(uint a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

     
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

     
    function isGreaterThan(Unsigned memory a, uint b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

     
    function isGreaterThan(uint a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

     
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

     
    function isLessThan(Unsigned memory a, uint b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

     
    function isLessThan(uint a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

     
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

     
    function add(Unsigned memory a, uint b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

     
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

     
    function sub(Unsigned memory a, uint b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

     
    function sub(uint a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

     
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
         
         
         
         
         
         
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

     
    function mul(Unsigned memory a, uint b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

     
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
         
         
         
         
         
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

     
    function div(Unsigned memory a, uint b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

     
    function div(uint a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

     
    function pow(Unsigned memory a, uint b) internal pure returns (Unsigned memory output) {
         
         
        output = fromUnscaledUint(1);
        for (uint i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

library Exclusive {
    struct RoleMembership {
        address member;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.member == memberToCheck;
    }

    function resetMember(RoleMembership storage roleMembership, address newMember) internal {
        require(newMember != address(0x0), "Cannot set an exclusive role to 0x0");
        roleMembership.member = newMember;
    }

    function getMember(RoleMembership storage roleMembership) internal view returns (address) {
        return roleMembership.member;
    }

    function init(RoleMembership storage roleMembership, address initialMember) internal {
        resetMember(roleMembership, initialMember);
    }
}

library Shared {
    struct RoleMembership {
        mapping(address => bool) members;
    }

    function isMember(RoleMembership storage roleMembership, address memberToCheck) internal view returns (bool) {
        return roleMembership.members[memberToCheck];
    }

    function addMember(RoleMembership storage roleMembership, address memberToAdd) internal {
        roleMembership.members[memberToAdd] = true;
    }

    function removeMember(RoleMembership storage roleMembership, address memberToRemove) internal {
        roleMembership.members[memberToRemove] = false;
    }

    function init(RoleMembership storage roleMembership, address[] memory initialMembers) internal {
        for (uint i = 0; i < initialMembers.length; i++) {
            addMember(roleMembership, initialMembers[i]);
        }
    }
}

contract MultiRole {
    using Exclusive for Exclusive.RoleMembership;
    using Shared for Shared.RoleMembership;

    enum RoleType { Invalid, Exclusive, Shared }

    struct Role {
        uint managingRole;
        RoleType roleType;
        Exclusive.RoleMembership exclusiveRoleMembership;
        Shared.RoleMembership sharedRoleMembership;
    }

    mapping(uint => Role) private roles;

     
    modifier onlyRoleHolder(uint roleId) {
        require(holdsRole(roleId, msg.sender), "Sender does not hold required role");
        _;
    }

     
    modifier onlyRoleManager(uint roleId) {
        require(holdsRole(roles[roleId].managingRole, msg.sender), "Can only be called by a role manager");
        _;
    }

     
    modifier onlyExclusive(uint roleId) {
        require(roles[roleId].roleType == RoleType.Exclusive, "Must be called on an initialized Exclusive role");
        _;
    }

     
    modifier onlyShared(uint roleId) {
        require(roles[roleId].roleType == RoleType.Shared, "Must be called on an initialized Shared role");
        _;
    }

     
    function holdsRole(uint roleId, address memberToCheck) public view returns (bool) {
        Role storage role = roles[roleId];
        if (role.roleType == RoleType.Exclusive) {
            return role.exclusiveRoleMembership.isMember(memberToCheck);
        } else if (role.roleType == RoleType.Shared) {
            return role.sharedRoleMembership.isMember(memberToCheck);
        }
        require(false, "Invalid roleId");
    }

     
    function resetMember(uint roleId, address newMember) public onlyExclusive(roleId) onlyRoleManager(roleId) {
        roles[roleId].exclusiveRoleMembership.resetMember(newMember);
    }

     
    function getMember(uint roleId) public view onlyExclusive(roleId) returns (address) {
        return roles[roleId].exclusiveRoleMembership.getMember();
    }

     
    function addMember(uint roleId, address newMember) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.addMember(newMember);
    }

     
    function removeMember(uint roleId, address memberToRemove) public onlyShared(roleId) onlyRoleManager(roleId) {
        roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
    }

     
    modifier onlyValidRole(uint roleId) {
        require(roles[roleId].roleType != RoleType.Invalid, "Attempted to use an invalid roleId");
        _;
    }

     
    modifier onlyInvalidRole(uint roleId) {
        require(roles[roleId].roleType == RoleType.Invalid, "Cannot use a pre-existing role");
        _;
    }

     
    function _createSharedRole(uint roleId, uint managingRoleId, address[] memory initialMembers)
        internal
        onlyInvalidRole(roleId)
    {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Shared;
        role.managingRole = managingRoleId;
        role.sharedRoleMembership.init(initialMembers);
        require(roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage a shared role");
    }

     
    function _createExclusiveRole(uint roleId, uint managingRoleId, address initialMember)
        internal
        onlyInvalidRole(roleId)
    {
        Role storage role = roles[roleId];
        role.roleType = RoleType.Exclusive;
        role.managingRole = managingRoleId;
        role.exclusiveRoleMembership.init(initialMember);
        require(roles[managingRoleId].roleType != RoleType.Invalid,
            "Attempted to use an invalid role to manage an exclusive role");
    }
}

interface StoreInterface {

     
    function payOracleFees() external payable;

     
    function payOracleFeesErc20(address erc20Address) external; 

     
    function computeRegularFee(uint startTime, uint endTime, FixedPoint.Unsigned calldata pfc) 
    external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);
    
     
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory finalFee);
}

contract Withdrawable is MultiRole {

    uint private _roleId;

     
    function withdraw(uint amount) external onlyRoleHolder(_roleId) {
        msg.sender.transfer(amount);
    }

     
    function withdrawErc20(address erc20Address, uint amount) external onlyRoleHolder(_roleId) {
        IERC20 erc20 = IERC20(erc20Address);
        require(erc20.transfer(msg.sender, amount));
    }

     
    function createWithdrawRole(uint roleId, uint managingRoleId, address owner) internal {
        _roleId = roleId;
        _createExclusiveRole(roleId, managingRoleId, owner);
    }

     
    function setWithdrawRole(uint roleId) internal {
        _roleId = roleId;
    }
}

contract Store is StoreInterface, MultiRole, Withdrawable {

    using SafeMath for uint;
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for uint;

    enum Roles {
        Owner,
        Withdrawer
    }

    FixedPoint.Unsigned private fixedOracleFeePerSecond;  

    FixedPoint.Unsigned private weeklyDelayFee;  
    mapping(address => FixedPoint.Unsigned) private finalFees;
    uint private constant SECONDS_PER_WEEK = 604800;

    event NewFixedOracleFeePerSecond(FixedPoint.Unsigned newOracleFee);

    constructor() public {
        _createExclusiveRole(uint(Roles.Owner), uint(Roles.Owner), msg.sender);
        createWithdrawRole(uint(Roles.Withdrawer), uint(Roles.Owner), msg.sender);
    }

    function payOracleFees() external payable {
        require(msg.value > 0);
    }

    function payOracleFeesErc20(address erc20Address) external {
        IERC20 erc20 = IERC20(erc20Address);
        uint authorizedAmount = erc20.allowance(msg.sender, address(this));
        require(authorizedAmount > 0);
        require(erc20.transferFrom(msg.sender, address(this), authorizedAmount));
    }

    function computeRegularFee(uint startTime, uint endTime, FixedPoint.Unsigned calldata pfc) 
        external 
        view 
        returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty) 
    {
        uint timeDiff = endTime.sub(startTime);

         
        regularFee = pfc.mul(timeDiff).mul(fixedOracleFeePerSecond);
         
        latePenalty = pfc.mul(weeklyDelayFee.mul(timeDiff.div(SECONDS_PER_WEEK)));

        return (regularFee, latePenalty);
    }

    function computeFinalFee(address currency) 
        external 
        view 
        returns (FixedPoint.Unsigned memory finalFee) 
    {
        finalFee = finalFees[currency];
    }

      
    function setFixedOracleFeePerSecond(FixedPoint.Unsigned memory newOracleFee) 
        public 
        onlyRoleHolder(uint(Roles.Owner)) 
    {
         
        require(newOracleFee.isLessThan(1));
        fixedOracleFeePerSecond = newOracleFee;
        emit NewFixedOracleFeePerSecond(newOracleFee);
    }

      
    function setWeeklyDelayFee(FixedPoint.Unsigned memory newWeeklyDelayFee) 
        public 
        onlyRoleHolder(uint(Roles.Owner)) 
    {
        weeklyDelayFee = newWeeklyDelayFee;
    }

      
    function setFinalFee(address currency, FixedPoint.Unsigned memory finalFee) 
        public 
        onlyRoleHolder(uint(Roles.Owner))
    {
        finalFees[currency] = finalFee;
    }
}

library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}