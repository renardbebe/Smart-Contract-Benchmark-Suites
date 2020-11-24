 

pragma solidity ^0.4.24;

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

contract AbstractDeployer is Ownable {
    function title() public view returns(string);

    function deploy(bytes data)
        external onlyOwner returns(address result)
    {
         
        require(address(this).call(data), "Arbitrary call failed");
         
        assembly {
            returndatacopy(0, 0, 32)
            result := mload(0)
        }
    }
}

 

contract IBasicMultiToken is ERC20 {
    event Bundle(address indexed who, address indexed beneficiary, uint256 value);
    event Unbundle(address indexed who, address indexed beneficiary, uint256 value);

    function tokensCount() public view returns(uint256);
    function tokens(uint i) public view returns(ERC20);
    function bundlingEnabled() public view returns(bool);
    
    function bundleFirstTokens(address _beneficiary, uint256 _amount, uint256[] _tokenAmounts) public;
    function bundle(address _beneficiary, uint256 _amount) public;

    function unbundle(address _beneficiary, uint256 _value) public;
    function unbundleSome(address _beneficiary, uint256 _value, ERC20[] _tokens) public;

     
    function disableBundling() public;
    function enableBundling() public;

    bytes4 public constant InterfaceId_IBasicMultiToken = 0xd5c368b6;
	   
}

 

contract IMultiToken is IBasicMultiToken {
    event Update();
    event Change(address indexed _fromToken, address indexed _toToken, address indexed _changer, uint256 _amount, uint256 _return);

    function weights(address _token) public view returns(uint256);
    function changesEnabled() public view returns(bool);
    
    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256 returnAmount);
    function change(address _fromToken, address _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256 returnAmount);

     
    function disableChanges() public;

    bytes4 public constant InterfaceId_IMultiToken = 0x81624e24;
	   
}

 

contract MultiTokenNetwork is Pausable {
    address[] private _multitokens;
    AbstractDeployer[] private _deployers;

    event NewMultitoken(address indexed mtkn);
    event NewDeployer(uint256 indexed index, address indexed oldDeployer, address indexed newDeployer);

    function multitokensCount() public view returns(uint256) {
        return _multitokens.length;
    }

    function multitokens(uint i) public view returns(address) {
        return _multitokens[i];
    }

    function allMultitokens() public view returns(address[]) {
        return _multitokens;
    }

    function deployersCount() public view returns(uint256) {
        return _deployers.length;
    }

    function deployers(uint i) public view returns(AbstractDeployer) {
        return _deployers[i];
    }

    function allWalletBalances(address wallet) public view returns(uint256[]) {
        uint256[] memory balances = new uint256[](_multitokens.length);
        for (uint i = 0; i < _multitokens.length; i++) {
            balances[i] = ERC20(_multitokens[i]).balanceOf(wallet);
        }
        return balances;
    }

    function deleteMultitoken(uint index) public onlyOwner {
        require(index < _multitokens.length, "deleteMultitoken: index out of range");
        if (index != _multitokens.length - 1) {
            _multitokens[index] = _multitokens[_multitokens.length - 1];
        }
        _multitokens.length -= 1;
    }

    function deleteDeployer(uint index) public onlyOwner {
        require(index < _deployers.length, "deleteDeployer: index out of range");
        if (index != _deployers.length - 1) {
            _deployers[index] = _deployers[_deployers.length - 1];
        }
        _deployers.length -= 1;
    }

    function disableBundlingMultitoken(uint index) public onlyOwner {
        IBasicMultiToken(_multitokens[index]).disableBundling();
    }

    function enableBundlingMultitoken(uint index) public onlyOwner {
        IBasicMultiToken(_multitokens[index]).enableBundling();
    }

    function disableChangesMultitoken(uint index) public onlyOwner {
        IMultiToken(_multitokens[index]).disableChanges();
    }

    function addDeployer(AbstractDeployer deployer) public onlyOwner whenNotPaused {
        require(deployer.owner() == address(this), "addDeployer: first set MultiTokenNetwork as owner");
        emit NewDeployer(_deployers.length, address(0), deployer);
        _deployers.push(deployer);
    }

    function setDeployer(uint256 index, AbstractDeployer deployer) public onlyOwner whenNotPaused {
        require(deployer.owner() == address(this), "setDeployer: first set MultiTokenNetwork as owner");
        emit NewDeployer(index, _deployers[index], deployer);
        _deployers[index] = deployer;
    }

    function deploy(uint256 index, bytes data) public whenNotPaused {
        address mtkn = _deployers[index].deploy(data);
        _multitokens.push(mtkn);
        emit NewMultitoken(mtkn);
    }

    function makeCall(address target, uint256 value, bytes data) public onlyOwner {
         
        require(target.call.value(value)(data), "Arbitrary call failed");
    }
}