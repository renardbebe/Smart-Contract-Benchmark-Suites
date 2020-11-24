 

 

 

pragma solidity 0.5.12;


interface Validating {
  modifier notZero(uint number) { require(number > 0, "invalid 0 value"); _; }
  modifier notEmpty(string memory text) { require(bytes(text).length > 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address"); _; }
}

 

pragma solidity 0.5.12;


contract Versioned {

  string public version;

  constructor(string memory version_) public { version = version_; }

}

 

pragma solidity 0.5.12;


 
library SafeMath {

  function min(uint x, uint y) internal pure returns (uint) { return x <= y ? x : y; }
  function max(uint x, uint y) internal pure returns (uint) { return x >= y ? x : y; }


   
  function plus(uint x, uint y) internal pure returns (uint z) { require((z = x + y) >= x, "bad addition"); }

   
  function minus(uint x, uint y) internal pure returns (uint z) { require((z = x - y) <= x, "bad subtraction"); }


   
  function times(uint x, uint y) internal pure returns (uint z) { require(y == 0 || (z = x * y) / y == x, "bad multiplication"); }

   
  function mod(uint x, uint y) internal pure returns (uint z) {
    require(y != 0, "bad modulo; using 0 as divisor");
    z = x % y;
  }

   
  function div(uint a, uint b) internal pure returns (uint c) {
     
    c = a / b;
     
  }

}

 

pragma solidity 0.5.12;


 
contract Token {
   
   
  uint public totalSupply;

   
   
  function balanceOf(address _owner) public view returns (uint balance);

   
   
   
   
  function transfer(address _to, uint _value) public returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);

   
   
   
   
  function approve(address _spender, uint _value) public returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) public view returns (uint remaining);

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 

pragma solidity 0.5.12;


interface AppGovernance {
  function approve(uint32 id) external;
  function disapprove(uint32 id) external;
  function activate(uint32 id) external;
}

 

pragma solidity 0.5.12;


interface AppLogic {
  function upgrade() external;
  function credit(address account, address asset, uint quantity) external;
  function debit(address account, bytes calldata parameters) external returns (address asset, uint quantity);
}

 

pragma solidity 0.5.12;


interface GluonView {
  function app(uint32 id) external view returns (address current, address proposal, uint activationBlock);
  function current(uint32 id) external view returns (address);
  function history(uint32 id) external view returns (address[] memory);
  function getBalance(uint32 id, address asset) external view returns (uint);
  function isAnyLogic(uint32 id, address logic) external view returns (bool);
  function isAppOwner(uint32 id, address appOwner) external view returns (bool);
  function proposals(address logic) external view returns (bool);
  function totalAppsCount() external view returns(uint32);
}

 

pragma solidity 0.5.12;


interface GluonWallet {
  function depositEther(uint32 id) external payable;
  function depositToken(uint32 id, address token, uint quantity) external;
  function withdraw(uint32 id, bytes calldata parameters) external;
  function transfer(uint32 from, uint32 to, bytes calldata parameters) external;
}

 

pragma solidity 0.5.12;


interface Governing {
  function deleteVoteTally(address proposal) external;
  function activationInterval() external view returns (uint);
}

 

pragma solidity 0.5.12;



contract HasOwners is Validating {

  address[] public owners;
  mapping(address => bool) public isOwner;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  constructor(address[] memory owners_) public {
    for (uint i = 0; i < owners_.length; i++) addOwner_(owners_[i]);
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  function getOwners() public view returns (address[] memory) { return owners; }

  function addOwner(address owner) external onlyOwner { addOwner_(owner); }

  function addOwner_(address owner) private validAddress(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }

  function removeOwner(address owner) external onlyOwner {
    require(isOwner[owner], 'only owners can be removed');
    require(owners.length > 1, 'can not remove last owner');
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        owners.pop();
        emit OwnerRemoved(owner);
        break;
      }
    }
  }

}

 

pragma solidity 0.5.12;



contract HasAppOwners is HasOwners {

  mapping(uint32 => address[]) public appOwners;

  event AppOwnerAdded (uint32 appId, address appOwner);
  event AppOwnerRemoved (uint32 appId, address appOwner);

  constructor(address[] memory owners) HasOwners(owners) public { }

  modifier onlyAppOwner(uint32 appId) { require(isAppOwner(appId, msg.sender), "invalid sender; must be app owner"); _; }

  function isAppOwner(uint32 appId, address appOwner) public view returns (bool) {
    address[] memory currentOwners = appOwners[appId];
    for (uint i = 0; i < currentOwners.length; i++) {
      if (currentOwners[i] == appOwner) return true;
    }
    return false;
  }

  function getAppOwners(uint32 appId) public view returns (address[] memory) { return appOwners[appId]; }

  function addAppOwners(uint32 appId, address[] calldata toBeAdded) external onlyAppOwner(appId) {
    addAppOwners_(appId, toBeAdded);
  }

  function addAppOwners_(uint32 appId, address[] memory toBeAdded) internal {
    for (uint i = 0; i < toBeAdded.length; i++) {
      if (!isAppOwner(appId, toBeAdded[i])) {
        appOwners[appId].push(toBeAdded[i]);
        emit AppOwnerAdded(appId, toBeAdded[i]);
      }
    }
  }


  function removeAppOwners(uint32 appId, address[] calldata toBeRemoved) external onlyAppOwner(appId) {
    address[] storage currentOwners = appOwners[appId];
    require(currentOwners.length > toBeRemoved.length, "can not remove last owner");
    for (uint i = 0; i < toBeRemoved.length; i++) {
      for (uint j = 0; j < currentOwners.length; j++) {
        if (currentOwners[j] == toBeRemoved[i]) {
          currentOwners[j] = currentOwners[currentOwners.length - 1];
          currentOwners.pop();
          emit AppOwnerRemoved(appId, toBeRemoved[i]);
          break;
        }
      }
    }
  }

}

 

pragma solidity 0.5.12;












contract Gluon is Validating, Versioned, AppGovernance, GluonView, GluonWallet, HasAppOwners {
  using SafeMath for uint;

  struct App {
    address[] history;
    address proposal;
    uint activationBlock;
    mapping(address => uint) balances;
  }

  address private constant ETH = address(0x0);
  uint32 private constant REGISTRY_INDEX = 0;
  uint32 private constant STAKE_INDEX = 1;

  mapping(uint32 => App) public apps;
  mapping(address => bool) public proposals;
  uint32 public totalAppsCount = 0;

  event AppRegistered (uint32 appId);
  event AppProvisioned(uint32 indexed appId, uint8 version, address logic);
  event ProposalAdded(uint32 indexed appId, uint8 version, address logic, uint activationBlock);
  event ProposalRemoved(uint32 indexed appId, uint8 version, address logic);
  event Activated(uint32 indexed appId, uint8 version, address logic);

  constructor(address[] memory owners, string memory version) Versioned(version) public HasAppOwners(owners) {
    registerApp_(REGISTRY_INDEX, owners);
    registerApp_(STAKE_INDEX, owners);
  }

  modifier onlyCurrentLogic(uint32 appId) { require(msg.sender == current(appId), "invalid sender; must be latest logic contract"); _; }
  modifier provisioned(uint32 appId) { require(apps[appId].history.length > 0, "App is not yet provisioned"); _; }

  function registerApp(uint32 appId, address[] calldata appOwners_) external onlyOwner { registerApp_(appId, appOwners_); }

  function registerApp_(uint32 appId, address[] memory appOwners_) private {
    require(appOwners[appId].length == 0, "App already has app owner");
    require(totalAppsCount == appId, "app ids are incremented by 1");
    totalAppsCount++;
    emit AppRegistered(appId);
    addAppOwners_(appId, appOwners_);
  }

  function provisionApp(uint32 appId, address logic) external onlyAppOwner(appId) validAddress(logic) {
    App storage app = apps[appId];
    require(app.history.length == 0, "App is already provisioned");
    app.history.push(logic);
    emit AppProvisioned(appId, uint8(app.history.length - 1), logic);
  }

  function addProposal(uint32 appId, address logic) external onlyAppOwner(appId) provisioned(appId) validAddress(logic) {
    App storage app = apps[appId];
    require(app.proposal == address(0), "Proposal already exists. remove proposal before adding new one");
    app.proposal = logic;
    app.activationBlock = block.number + Governing(current(STAKE_INDEX)).activationInterval();
    proposals[logic] = true;
    emit ProposalAdded(appId, uint8(app.history.length - 1), app.proposal, app.activationBlock);
  }

  function removeProposal(uint32 appId) external onlyAppOwner(appId) provisioned(appId) {
    App storage app = apps[appId];
    emit ProposalRemoved(appId, uint8(app.history.length - 1), app.proposal);
    deleteProposal(app);
  }

  function deleteProposal(App storage app) private {
    Governing(current(STAKE_INDEX)).deleteVoteTally(app.proposal);
    delete proposals[app.proposal];
    delete app.proposal;
    app.activationBlock = 0;
  }

   

  function approve(uint32 appId) external onlyCurrentLogic(STAKE_INDEX) {
    apps[appId].activationBlock = block.number;
  }

  function disapprove(uint32 appId) external onlyCurrentLogic(STAKE_INDEX) {
    App storage app = apps[appId];
    emit ProposalRemoved(appId, uint8(app.history.length - 1), app.proposal);
    deleteProposal(app);
  }

  function activate(uint32 appId) external onlyCurrentLogic(appId) provisioned(appId) {
    App storage app = apps[appId];
    require(app.activationBlock > 0, "nothing to activate");
    require(app.activationBlock < block.number, "new app can not be activated before activation block");
    app.history.push(app.proposal);  
    deleteProposal(app);
    emit Activated(appId, uint8(app.history.length - 1), current(appId));
  }

   

  function depositEther(uint32 appId) external payable provisioned(appId) {
    App storage app = apps[appId];
    app.balances[ETH] = app.balances[ETH].plus(msg.value);
    AppLogic(current(appId)).credit(msg.sender, ETH, msg.value);
  }

   
  function depositToken(uint32 appId, address token, uint quantity) external provisioned(appId) {
    transferTokensToGluonSecurely(appId, Token(token), quantity);
    AppLogic(current(appId)).credit(msg.sender, token, quantity);
  }

  function transferTokensToGluonSecurely(uint32 appId, Token token, uint quantity) private {
    uint balanceBefore = token.balanceOf(address(this));
    require(token.transferFrom(msg.sender, address(this), quantity), "failure to transfer quantity from token");
    uint balanceAfter = token.balanceOf(address(this));
    require(balanceAfter.minus(balanceBefore) == quantity, "bad Token; transferFrom erroneously reported of successful transfer");
    App storage app = apps[appId];
    app.balances[address(token)] = app.balances[address(token)].plus(quantity);
  }

  function withdraw(uint32 appId, bytes calldata parameters) external provisioned(appId) {
    (address asset, uint quantity) = AppLogic(current(appId)).debit(msg.sender, parameters);
    if (quantity > 0) {
      App storage app = apps[appId];
      require(app.balances[asset] >= quantity, "not enough funds to transfer");
      app.balances[asset] = apps[appId].balances[asset].minus(quantity);
      asset == ETH ?
        require(address(uint160(msg.sender)).send(quantity), "failed to transfer ether") :  
        transferTokensToAccountSecurely(Token(asset), quantity, msg.sender);
    }
  }

  function transferTokensToAccountSecurely(Token token, uint quantity, address to) private {
    uint balanceBefore = token.balanceOf(to);
    require(token.transfer(to, quantity), "failure to transfer quantity from token");
    uint balanceAfter = token.balanceOf(to);
    require(balanceAfter.minus(balanceBefore) == quantity, "bad Token; transferFrom erroneously reported of successful transfer");
  }

  function transfer(uint32 from, uint32 to, bytes calldata parameters) external provisioned(from) provisioned(to) {
    (address asset, uint quantity) = AppLogic(current(from)).debit(msg.sender, parameters);
    if (quantity > 0) {
      if (from != to) {
        require(apps[from].balances[asset] >= quantity, "not enough balance in logic to transfer");
        apps[from].balances[asset] = apps[from].balances[asset].minus(quantity);
        apps[to].balances[asset] = apps[to].balances[asset].plus(quantity);
      }
      AppLogic(current(to)).credit(msg.sender, asset, quantity);
    }
  }

   

  function app(uint32 appId) external view returns (address current, address proposal, uint activationBlock) {
    App memory app_ = apps[appId];
    current = app_.history[app_.history.length - 1];
    proposal = app_.proposal;
    activationBlock = app_.activationBlock;
  }

  function current(uint32 appId) public view returns (address) { return apps[appId].history[apps[appId].history.length - 1]; }

  function history(uint32 appId) external view returns (address[] memory) { return apps[appId].history; }

  function isAnyLogic(uint32 appId, address logic) public view returns (bool) {
    address[] memory history_ = apps[appId].history;
    for (uint i = history_.length; i > 0; i--) {
      if (history_[i - 1] == logic) return true;
    }
    return false;
  }

  function getBalance(uint32 appId, address asset) external view returns (uint) { return apps[appId].balances[asset]; }

}