 

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.4;



 

contract Reputation is Ownable {

    uint8 public decimals = 18;              
     
    event Mint(address indexed _to, uint256 _amount);
     
    event Burn(address indexed _from, uint256 _amount);

       
       
       
    struct Checkpoint {

     
        uint128 fromBlock;

           
        uint128 value;
    }

       
       
       
    mapping (address => Checkpoint[]) balances;

       
    Checkpoint[] totalSupplyHistory;

     
    constructor(
    ) public
    {
    }

     
     
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

   
   
   
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

       
       
       
       
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

       
       
       
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            return 0;
           
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

       
       
       
       
    function mint(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply);  
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo);  
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

       
       
       
       
    function burn(address _user, uint256 _amount) public onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

   
   
   

       
       
       
       
    function getValueAt(Checkpoint[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

           
        if (_block >= checkpoints[checkpoints.length-1].fromBlock) {
            return checkpoints[checkpoints.length-1].value;
        }
        if (_block < checkpoints[0].fromBlock) {
            return 0;
        }

           
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

       
       
       
       
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value);  
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length-1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

pragma solidity ^0.5.4;





 

contract DAOToken is ERC20, ERC20Burnable, Ownable {

    string public name;
    string public symbol;
     
    uint8 public constant decimals = 18;
    uint256 public cap;

     
    constructor(string memory _name, string memory _symbol, uint256 _cap)
    public {
        name = _name;
        symbol = _symbol;
        cap = _cap;
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (cap > 0)
            require(totalSupply().add(_amount) <= cap);
        _mint(_to, _amount);
        return true;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 
pragma solidity ^0.5.4;



library SafeERC20 {
    using Address for address;

    bytes4 constant private TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 constant private TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 constant private APPROVE_SELECTOR = bytes4(keccak256(bytes("approve(address,uint256)")));

    function safeTransfer(address _erc20Addr, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFER_SELECTOR, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeTransferFrom(address _erc20Addr, address _from, address _to, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, _from, _to, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }

    function safeApprove(address _erc20Addr, address _spender, uint256 _value) internal {

         
        require(_erc20Addr.isContract());

         
         
        require((_value == 0) || (IERC20(_erc20Addr).allowance(address(this), _spender) == 0));

        (bool success, bytes memory returnValue) =
         
        _erc20Addr.call(abi.encodeWithSelector(APPROVE_SELECTOR, _spender, _value));
         
        require(success);
         
        require(returnValue.length == 0 || (returnValue.length == 32 && (returnValue[31] != 0)));
    }
}

 

pragma solidity ^0.5.4;







 
contract Avatar is Ownable {
    using SafeERC20 for address;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;

    event GenericCall(address indexed _contract, bytes _params, bool _success);
    event SendEther(uint256 _amountInWei, address indexed _to);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint256 _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint256 _value);
    event ExternalTokenApproval(address indexed _externalToken, address _spender, uint256 _value);
    event ReceiveEther(address indexed _sender, uint256 _value);
    event MetaData(string _metaData);

     
    constructor(string memory _orgName, DAOToken _nativeToken, Reputation _nativeReputation) public {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
    }

     
    function() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

     
    function genericCall(address _contract, bytes memory _data)
    public
    onlyOwner
    returns(bool success, bytes memory returnValue) {
       
        (success, returnValue) = _contract.call(_data);
        emit GenericCall(_contract, _data, success);
    }

     
    function sendEther(uint256 _amountInWei, address payable _to) public onlyOwner returns(bool) {
        _to.transfer(_amountInWei);
        emit SendEther(_amountInWei, _to);
        return true;
    }

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransfer(_to, _value);
        emit ExternalTokenTransfer(address(_externalToken), _to, _value);
        return true;
    }

     
    function externalTokenTransferFrom(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeTransferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(address(_externalToken), _from, _to, _value);
        return true;
    }

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    public onlyOwner returns(bool)
    {
        address(_externalToken).safeApprove(_spender, _value);
        emit ExternalTokenApproval(address(_externalToken), _spender, _value);
        return true;
    }

     
    function metaData(string memory _metaData) public onlyOwner returns(bool) {
        emit MetaData(_metaData);
        return true;
    }


}

 

pragma solidity ^0.5.4;


contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function pre( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
    function post( address _scheme, bytes32 _params, bytes32 _method ) public returns(bool);
     
    function when() public returns(CallPhase);
}

 

pragma solidity ^0.5.4;



 
interface ControllerInterface {

     
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    returns(bool);

     
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    returns(bool);

     
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    returns(bool);

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    returns(bool);

     
    function unregisterScheme(address _scheme, address _avatar)
    external
    returns(bool);

     
    function unregisterSelf(address _avatar) external returns(bool);

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external returns(bool);

     
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external  returns(bool);

   
    function upgradeController(address _newController, Avatar _avatar)
    external returns(bool);

     
    function genericCall(address _contract, bytes calldata _data, Avatar _avatar)
    external
    returns(bool, bytes memory);

   
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external returns(bool);

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    returns(bool);

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    returns(bool);

     
    function metaData(string calldata _metaData, Avatar _avatar) external returns(bool);

     
    function getNativeReputation(address _avatar)
    external
    view
    returns(address);

    function isSchemeRegistered( address _scheme, address _avatar) external view returns(bool);

    function getSchemeParameters(address _scheme, address _avatar) external view returns(bytes32);

    function getGlobalConstraintParameters(address _globalConstraint, address _avatar) external view returns(bytes32);

    function getSchemePermissions(address _scheme, address _avatar) external view returns(bytes4);

     
    function globalConstraintsCount(address _avatar) external view returns(uint, uint);

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar) external view returns(bool);
}

 

pragma solidity ^0.5.4;





 
contract UController is ControllerInterface {

    struct Scheme {
        bytes32 paramsHash;   
        bytes4  permissions;  
                             
                             
                             
                             
                             
                             
    }

    struct GlobalConstraint {
        address gcAddress;
        bytes32 params;
    }

    struct GlobalConstraintRegister {
        bool isRegistered;  
        uint256 index;     
    }

    struct Organization {
        DAOToken                  nativeToken;
        Reputation                nativeReputation;
        mapping(address=>Scheme)  schemes;
       
        GlobalConstraint[] globalConstraintsPre;
         
        GlobalConstraint[] globalConstraintsPost;
       
        mapping(address=>GlobalConstraintRegister) globalConstraintsRegisterPre;
       
        mapping(address=>GlobalConstraintRegister) globalConstraintsRegisterPost;
        bool exist;
    }

     
    mapping(address=>Organization) public organizations;
   
   
    mapping(address=>address) public newControllers; 

     
    mapping(address=>bool) public reputations;
     
    mapping(address=>bool) public tokens;


    event MintReputation (address indexed _sender, address indexed _to, uint256 _amount, address indexed _avatar);
    event BurnReputation (address indexed _sender, address indexed _from, uint256 _amount, address indexed _avatar);
    event MintTokens (address indexed _sender, address indexed _beneficiary, uint256 _amount, address indexed _avatar);
    event RegisterScheme (address indexed _sender, address indexed _scheme, address indexed _avatar);
    event UnregisterScheme (address indexed _sender, address indexed _scheme, address indexed _avatar);
    event UpgradeController(address indexed _oldController, address _newController, address _avatar);

    event AddGlobalConstraint(
        address indexed _globalConstraint,
        bytes32 _params,
        GlobalConstraintInterface.CallPhase _when,
        address indexed _avatar
    );

    event RemoveGlobalConstraint(
        address indexed _globalConstraint,
        uint256 _index,
        bool _isPre,
        address indexed _avatar
    );

    
    function newOrganization(
        Avatar _avatar
    ) external
    {
        require(!organizations[address(_avatar)].exist);
        require(_avatar.owner() == address(this));
        DAOToken nativeToken = _avatar.nativeToken();
        Reputation nativeReputation = _avatar.nativeReputation();
         
        require(!reputations[address(nativeReputation)]);
         
        require(!tokens[address(nativeToken)]);
        organizations[address(_avatar)].exist = true;
        organizations[address(_avatar)].nativeToken = nativeToken;
        organizations[address(_avatar)].nativeReputation = nativeReputation;
        reputations[address(nativeReputation)] = true;
        tokens[address(nativeToken)] = true;
        organizations[address(_avatar)].schemes[msg.sender] =
        Scheme({paramsHash: bytes32(0), permissions: bytes4(0x0000001f)});
        emit RegisterScheme(msg.sender, msg.sender, address(_avatar));
    }

   
    modifier onlyRegisteredScheme(address avatar) {
        require(organizations[avatar].schemes[msg.sender].permissions&bytes4(0x00000001) == bytes4(0x00000001));
        _;
    }

    modifier onlyRegisteringSchemes(address avatar) {
        require(organizations[avatar].schemes[msg.sender].permissions&bytes4(0x00000002) == bytes4(0x00000002));
        _;
    }

    modifier onlyGlobalConstraintsScheme(address avatar) {
        require(organizations[avatar].schemes[msg.sender].permissions&bytes4(0x00000004) == bytes4(0x00000004));
        _;
    }

    modifier onlyUpgradingScheme(address _avatar) {
        require(organizations[_avatar].schemes[msg.sender].permissions&bytes4(0x00000008) == bytes4(0x00000008));
        _;
    }

    modifier onlyGenericCallScheme(address _avatar) {
        require(organizations[_avatar].schemes[msg.sender].permissions&bytes4(0x00000010) == bytes4(0x00000010));
        _;
    }

    modifier onlyMetaDataScheme(address _avatar) {
        require(organizations[_avatar].schemes[msg.sender].permissions&bytes4(0x00000010) == bytes4(0x00000010));
        _;
    }

    modifier onlySubjectToConstraint(bytes32 func, address _avatar) {
        uint256 idx;
        GlobalConstraint[] memory globalConstraintsPre = organizations[_avatar].globalConstraintsPre;
        GlobalConstraint[] memory globalConstraintsPost = organizations[_avatar].globalConstraintsPost;
        for (idx = 0; idx < globalConstraintsPre.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPre[idx].gcAddress))
            .pre(msg.sender, globalConstraintsPre[idx].params, func));
        }
        _;
        for (idx = 0; idx < globalConstraintsPost.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPost[idx].gcAddress))
            .post(msg.sender, globalConstraintsPost[idx].params, func));
        }
    }

     
    function mintReputation(uint256 _amount, address _to, address _avatar)
    external
    onlyRegisteredScheme(_avatar)
    onlySubjectToConstraint("mintReputation", _avatar)
    returns(bool)
    {
        emit MintReputation(msg.sender, _to, _amount, _avatar);
        return organizations[_avatar].nativeReputation.mint(_to, _amount);
    }

     
    function burnReputation(uint256 _amount, address _from, address _avatar)
    external
    onlyRegisteredScheme(_avatar)
    onlySubjectToConstraint("burnReputation", _avatar)
    returns(bool)
    {
        emit BurnReputation(msg.sender, _from, _amount, _avatar);
        return organizations[_avatar].nativeReputation.burn(_from, _amount);
    }

     
    function mintTokens(uint256 _amount, address _beneficiary, address _avatar)
    external
    onlyRegisteredScheme(_avatar)
    onlySubjectToConstraint("mintTokens", _avatar)
    returns(bool)
    {
        emit MintTokens(msg.sender, _beneficiary, _amount, _avatar);
        return organizations[_avatar].nativeToken.mint(_beneficiary, _amount);
    }

   
    function registerScheme(address _scheme, bytes32 _paramsHash, bytes4 _permissions, address _avatar)
    external
    onlyRegisteringSchemes(_avatar)
    onlySubjectToConstraint("registerScheme", _avatar)
    returns(bool)
    {
        bytes4 schemePermission = organizations[_avatar].schemes[_scheme].permissions;
        bytes4 senderPermission = organizations[_avatar].schemes[msg.sender].permissions;
     
     

     
        require(bytes4(0x0000001f)&(_permissions^schemePermission)&(~senderPermission) == bytes4(0));

     
        require(bytes4(0x0000001f)&(schemePermission&(~senderPermission)) == bytes4(0));

     
        organizations[_avatar].schemes[_scheme] =
        Scheme({paramsHash:_paramsHash, permissions:_permissions|bytes4(0x00000001)});
        emit RegisterScheme(msg.sender, _scheme, _avatar);
        return true;
    }

     
    function unregisterScheme(address _scheme, address _avatar)
    external
    onlyRegisteringSchemes(_avatar)
    onlySubjectToConstraint("unregisterScheme", _avatar)
    returns(bool)
    {
        bytes4 schemePermission = organizations[_avatar].schemes[_scheme].permissions;
     
        if (schemePermission&bytes4(0x00000001) == bytes4(0)) {
            return false;
        }
     
        require(
        bytes4(0x0000001f)&(schemePermission&(~organizations[_avatar].schemes[msg.sender].permissions)) == bytes4(0));

     
        emit UnregisterScheme(msg.sender, _scheme, _avatar);
        delete organizations[_avatar].schemes[_scheme];
        return true;
    }

     
    function unregisterSelf(address _avatar) external returns(bool) {
        if (_isSchemeRegistered(msg.sender, _avatar) == false) {
            return false;
        }
        delete organizations[_avatar].schemes[msg.sender];
        emit UnregisterScheme(msg.sender, msg.sender, _avatar);
        return true;
    }

     
    function addGlobalConstraint(address _globalConstraint, bytes32 _params, address _avatar)
    external onlyGlobalConstraintsScheme(_avatar) returns(bool)
    {
        Organization storage organization = organizations[_avatar];
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!organization.globalConstraintsRegisterPre[_globalConstraint].isRegistered) {
                organization.globalConstraintsPre.push(GlobalConstraint(_globalConstraint, _params));
                organization.globalConstraintsRegisterPre[_globalConstraint] =
                GlobalConstraintRegister(true, organization.globalConstraintsPre.length-1);
            }else {
                organization
                .globalConstraintsPre[organization.globalConstraintsRegisterPre[_globalConstraint].index]
                .params = _params;
            }
        }

        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!organization.globalConstraintsRegisterPost[_globalConstraint].isRegistered) {
                organization.globalConstraintsPost.push(GlobalConstraint(_globalConstraint, _params));
                organization.globalConstraintsRegisterPost[_globalConstraint] =
                GlobalConstraintRegister(true, organization.globalConstraintsPost.length-1);
            } else {
                organization
                .globalConstraintsPost[organization.globalConstraintsRegisterPost[_globalConstraint].index]
                .params = _params;
            }
        }
        emit AddGlobalConstraint(_globalConstraint, _params, when, _avatar);
        return true;
    }

     
    function removeGlobalConstraint (address _globalConstraint, address _avatar)
    external onlyGlobalConstraintsScheme(_avatar) returns(bool)
    {
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            removeGlobalConstraintPre(_globalConstraint, _avatar);
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            removeGlobalConstraintPost(_globalConstraint, _avatar);
        }
        return true;
    }

   
    function upgradeController(address _newController, Avatar _avatar)
    external onlyUpgradingScheme(address(_avatar)) returns(bool)
    {
        require(newControllers[address(_avatar)] == address(0));    
        require(_newController != address(0));
        newControllers[address(_avatar)] = _newController;
        _avatar.transferOwnership(_newController);
        require(_avatar.owner() == _newController);
        if (organizations[address(_avatar)].nativeToken.owner() == address(this)) {
            organizations[address(_avatar)].nativeToken.transferOwnership(_newController);
            require(organizations[address(_avatar)].nativeToken.owner() == _newController);
        }
        if (organizations[address(_avatar)].nativeReputation.owner() == address(this)) {
            organizations[address(_avatar)].nativeReputation.transferOwnership(_newController);
            require(organizations[address(_avatar)].nativeReputation.owner() == _newController);
        }
        emit UpgradeController(address(this), _newController, address(_avatar));
        return true;
    }

     
    function genericCall(address _contract, bytes calldata _data, Avatar _avatar)
    external
    onlyGenericCallScheme(address(_avatar))
    onlySubjectToConstraint("genericCall", address(_avatar))
    returns (bool, bytes memory)
    {
        return _avatar.genericCall(_contract, _data);
    }

   
    function sendEther(uint256 _amountInWei, address payable _to, Avatar _avatar)
    external
    onlyRegisteredScheme(address(_avatar))
    onlySubjectToConstraint("sendEther", address(_avatar))
    returns(bool)
    {
        return _avatar.sendEther(_amountInWei, _to);
    }

     
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value, Avatar _avatar)
    external
    onlyRegisteredScheme(address(_avatar))
    onlySubjectToConstraint("externalTokenTransfer", address(_avatar))
    returns(bool)
    {
        return _avatar.externalTokenTransfer(_externalToken, _to, _value);
    }

     
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value,
    Avatar _avatar)
    external
    onlyRegisteredScheme(address(_avatar))
    onlySubjectToConstraint("externalTokenTransferFrom", address(_avatar))
    returns(bool)
    {
        return _avatar.externalTokenTransferFrom(_externalToken, _from, _to, _value);
    }

     
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value, Avatar _avatar)
    external
    onlyRegisteredScheme(address(_avatar))
    onlySubjectToConstraint("externalTokenApproval", address(_avatar))
    returns(bool)
    {
        return _avatar.externalTokenApproval(_externalToken, _spender, _value);
    }

     
    function metaData(string calldata _metaData, Avatar _avatar)
        external
        onlyMetaDataScheme(address(_avatar))
        returns(bool)
        {
        return _avatar.metaData(_metaData);
    }

    function isSchemeRegistered( address _scheme, address _avatar) external view returns(bool) {
        return _isSchemeRegistered(_scheme, _avatar);
    }

    function getSchemeParameters(address _scheme, address _avatar) external view returns(bytes32) {
        return organizations[_avatar].schemes[_scheme].paramsHash;
    }

    function getSchemePermissions(address _scheme, address _avatar) external view returns(bytes4) {
        return organizations[_avatar].schemes[_scheme].permissions;
    }

    function getGlobalConstraintParameters(address _globalConstraint, address _avatar) external view returns(bytes32) {

        Organization storage organization = organizations[_avatar];

        GlobalConstraintRegister memory register = organization.globalConstraintsRegisterPre[_globalConstraint];

        if (register.isRegistered) {
            return organization.globalConstraintsPre[register.index].params;
        }

        register = organization.globalConstraintsRegisterPost[_globalConstraint];

        if (register.isRegistered) {
            return organization.globalConstraintsPost[register.index].params;
        }
    }

    
    function globalConstraintsCount(address _avatar) external view returns(uint, uint) {
        return (
        organizations[_avatar].globalConstraintsPre.length,
        organizations[_avatar].globalConstraintsPost.length
        );
    }

    function isGlobalConstraintRegistered(address _globalConstraint, address _avatar) external view returns(bool) {
        return (organizations[_avatar].globalConstraintsRegisterPre[_globalConstraint].isRegistered ||
        organizations[_avatar].globalConstraintsRegisterPost[_globalConstraint].isRegistered);
    }

     
    function getNativeReputation(address _avatar) external view returns(address) {
        return address(organizations[_avatar].nativeReputation);
    }

     
    function removeGlobalConstraintPre(address _globalConstraint, address _avatar)
    private returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister =
        organizations[_avatar].globalConstraintsRegisterPre[_globalConstraint];
        GlobalConstraint[] storage globalConstraints = organizations[_avatar].globalConstraintsPre;

        if (globalConstraintRegister.isRegistered) {
            if (globalConstraintRegister.index < globalConstraints.length-1) {
                GlobalConstraint memory globalConstraint = globalConstraints[globalConstraints.length-1];
                globalConstraints[globalConstraintRegister.index] = globalConstraint;
                organizations[_avatar].globalConstraintsRegisterPre[globalConstraint.gcAddress].index =
                globalConstraintRegister.index;
            }
            globalConstraints.length--;
            delete organizations[_avatar].globalConstraintsRegisterPre[_globalConstraint];
            emit RemoveGlobalConstraint(_globalConstraint, globalConstraintRegister.index, true, _avatar);
            return true;
        }
        return false;
    }

     
    function removeGlobalConstraintPost(address _globalConstraint, address _avatar)
    private returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister =
        organizations[_avatar].globalConstraintsRegisterPost[_globalConstraint];
        GlobalConstraint[] storage globalConstraints = organizations[_avatar].globalConstraintsPost;

        if (globalConstraintRegister.isRegistered) {
            if (globalConstraintRegister.index < globalConstraints.length-1) {
                GlobalConstraint memory globalConstraint = globalConstraints[globalConstraints.length-1];
                globalConstraints[globalConstraintRegister.index] = globalConstraint;
                organizations[_avatar].globalConstraintsRegisterPost[globalConstraint.gcAddress].index =
                globalConstraintRegister.index;
            }
            globalConstraints.length--;
            delete organizations[_avatar].globalConstraintsRegisterPost[_globalConstraint];
            emit RemoveGlobalConstraint(_globalConstraint, globalConstraintRegister.index, false, _avatar);
            return true;
        }
        return false;
    }

    function _isSchemeRegistered( address _scheme, address _avatar) private view returns(bool) {
        return (organizations[_avatar].schemes[_scheme].permissions&bytes4(0x00000001) != bytes4(0));
    }
}