 

pragma solidity 0.4.25;

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
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

interface IRemoteFunctions {
  function _externalAddMasternode(address) external;
  function _externalStopMasternode(address) external;
  function isMasternodeOwner(address) external view returns (bool);
  function userHasActiveNodes(address) external view returns (bool);
}

interface ICaelumMasternode {
    function _externalArrangeFlow() external;
    function rewardsProofOfWork() external view returns (uint) ;
    function rewardsMasternode() external view returns (uint) ;
    function masternodeIDcounter() external view returns (uint) ;
    function masternodeCandidate() external view returns (uint) ; 
    function getUserFromID(uint) external view returns  (address) ;
    function userCounter() external view returns(uint);
    function contractProgress() external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
}

contract ERC20Basic {
    function totalSupply() public view returns(uint256);

    function balanceOf(address _who) public view returns(uint256);

    function transfer(address _to, uint256 _value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address _owner, address _spender) public view returns(uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool);

    function approve(address _spender, uint256 _value) public returns(bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BasicToken is ERC20Basic {
    using SafeMath
    for uint256;

    mapping(address => uint256) internal balances;

    uint256 internal totalSupply_;

     
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

}

contract StandardToken is ERC20, BasicToken {

    mapping(address => mapping(address => uint256)) internal allowed;


     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns(uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns(bool) {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract InterfaceContracts is Ownable {
    InterfaceContracts public _internalMod;
    
    function setModifierContract (address _t) onlyOwner public {
        _internalMod = InterfaceContracts(_t);
    }

    modifier onlyMiningContract() {
      require(msg.sender == _internalMod._contract_miner(), "Wrong sender");
          _;
      }

    modifier onlyTokenContract() {
      require(msg.sender == _internalMod._contract_token(), "Wrong sender");
      _;
    }
    
    modifier onlyMasternodeContract() {
      require(msg.sender == _internalMod._contract_masternode(), "Wrong sender");
      _;
    }
    
    modifier onlyVotingOrOwner() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
    
    modifier onlyVotingContract() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
      
    function _contract_voting () public view returns (address) {
        return _internalMod._contract_voting();
    }
    
    function _contract_masternode () public view returns (address) {
        return _internalMod._contract_masternode();
    }
    
    function _contract_token () public view returns (address) {
        return _internalMod._contract_token();
    }
    
    function _contract_miner () public view returns (address) {
        return _internalMod._contract_miner();
    }
}

contract CaelumAcceptERC20  is InterfaceContracts {
    using SafeMath for uint;

    address[] public tokensList;
    bool setOwnContract = true;

    struct _whitelistTokens {
        address tokenAddress;
        bool active;
        uint requiredAmount;
        uint validUntil;
        uint timestamp;
    }

    mapping(address => mapping(address => uint)) public tokens;
    mapping(address => _whitelistTokens) acceptedTokens;

    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

     
    function addOwnToken() internal returns(bool) {
        require(setOwnContract);
        addToWhitelist(this, 5000 * 1e8, 36500);
        setOwnContract = false;
        return true;
    }


     
    function addToWhitelist(address _token, uint _amount, uint daysAllowed) internal {
        _whitelistTokens storage newToken = acceptedTokens[_token];
        newToken.tokenAddress = _token;
        newToken.requiredAmount = _amount;
        newToken.timestamp = now;
        newToken.validUntil = now + (daysAllowed * 1 days);
        newToken.active = true;

        tokensList.push(_token);
    }

     
    function isAcceptedToken(address _ad) internal view returns(bool) {
        return acceptedTokens[_ad].active;
    }

     
    function getAcceptedTokenAmount(address _ad) internal view returns(uint) {
        return acceptedTokens[_ad].requiredAmount;
    }

     
    function isValid(address _ad) internal view returns(bool) {
        uint endTime = acceptedTokens[_ad].validUntil;
        if (block.timestamp < endTime) return true;
        return false;
    }

     
    function listAcceptedTokens() public view returns(address[]) {
        return tokensList;
    }

     
    function getTokenDetails(address token) public view returns(address ad, uint required, bool active, uint valid) {
        return (acceptedTokens[token].tokenAddress, acceptedTokens[token].requiredAmount, acceptedTokens[token].active, acceptedTokens[token].validUntil);
    }

     
    function depositCollateral(address token, uint amount) public {

        require(isAcceptedToken(token), "ERC20 not authorised");  
        require(amount == getAcceptedTokenAmount(token));  
        require(isValid(token));  


        tokens[token][msg.sender] = tokens[token][msg.sender].add(amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);

        require(StandardToken(token).transferFrom(msg.sender, this, amount), "error with transfer");
        IRemoteFunctions(_contract_masternode())._externalAddMasternode(msg.sender);
    }

     
    function withdrawCollateral(address token, uint amount) public {
        require(token != 0, "No token specified");  
        require(isAcceptedToken(token), "ERC20 not authorised");  
        require(amount == getAcceptedTokenAmount(token));  
        uint amountToWithdraw = amount;

        tokens[token][msg.sender] = tokens[token][msg.sender] - amount;
        emit Withdraw(token, msg.sender, amountToWithdraw, amountToWithdraw);

        require(StandardToken(token).transfer(msg.sender, amountToWithdraw),"error with transfer");
        IRemoteFunctions(_contract_masternode())._externalStopMasternode(msg.sender);
    }

}

contract CaelumToken is CaelumAcceptERC20, StandardToken {
    using SafeMath for uint;

    ICaelumMasternode public masternodeInterface;

    bool public swapClosed = false;
    bool isOnTestNet = true;

    string public symbol = "CLM";
    string public name = "Caelum Token";
    uint8 public decimals = 8;
    uint256 public totalSupply = 2100000000000000;

    address allowedSwapAddress01 = 0x7600bF5112945F9F006c216d5d6db0df2806eDc6;
    address allowedSwapAddress02 = 0x16Da16948e5092A3D2aA71Aca7b57b8a9CFD8ddb;

    uint swapStartedBlock;

    mapping(address => uint) manualSwaps;
    mapping(address => bool) hasSwapped;

    event NewSwapRequest(address _swapper, uint _amount);
    event TokenSwapped(address _swapper, uint _amount);

    constructor() public {
        addOwnToken();
        swapStartedBlock = now;
    }

     
    function upgradeTokens(address _token) public {
        require(!hasSwapped[msg.sender], "User already swapped");
        require(now <= swapStartedBlock + 1 days, "Timeframe exipred, please use manualUpgradeTokens function");
        require(_token == allowedSwapAddress01 || _token == allowedSwapAddress02, "Token not allowed to swap.");

        uint amountToUpgrade = ERC20(_token).balanceOf(msg.sender);

        require(amountToUpgrade <= ERC20(_token).allowance(msg.sender, this));
        require(ERC20(_token).transferFrom(msg.sender, this, amountToUpgrade));
        require(ERC20(_token).balanceOf(msg.sender) == 0);

        tokens[_token][msg.sender] = tokens[_token][msg.sender].add(amountToUpgrade);
        balances[msg.sender] = balances[msg.sender].add(amountToUpgrade);

        emit Transfer(this, msg.sender, amountToUpgrade);
        emit TokenSwapped(msg.sender, amountToUpgrade);

        if(
          ERC20(allowedSwapAddress01).balanceOf(msg.sender) == 0  &&
          ERC20(allowedSwapAddress02).balanceOf(msg.sender) == 0
        ) {
          hasSwapped[msg.sender] = true;
        }

    }

     
    function manualUpgradeTokens(address _token) public {
        require(!hasSwapped[msg.sender], "User already swapped");
        require(now >= swapStartedBlock + 1 days, "Timeframe incorrect");
        require(_token == allowedSwapAddress01 || _token == allowedSwapAddress02, "Token not allowed to swap.");

        uint amountToUpgrade = ERC20(_token).balanceOf(msg.sender);
        require(amountToUpgrade <= ERC20(_token).allowance(msg.sender, this));

        if (ERC20(_token).transferFrom(msg.sender, this, amountToUpgrade)) {
            require(ERC20(_token).balanceOf(msg.sender) == 0);
            if(
              ERC20(allowedSwapAddress01).balanceOf(msg.sender) == 0  &&
              ERC20(allowedSwapAddress02).balanceOf(msg.sender) == 0
            ) {
              hasSwapped[msg.sender] = true;
            }

            tokens[_token][msg.sender] = tokens[_token][msg.sender].add(amountToUpgrade);
            manualSwaps[msg.sender] = amountToUpgrade;
            emit NewSwapRequest(msg.sender, amountToUpgrade);
        }
    }

     
    function manualUpgradePartialTokens(address _token, uint _amount) public {
        require(!hasSwapped[msg.sender], "User already swapped");
        require(now >= swapStartedBlock + 1 days, "Timeframe incorrect");
        require(_token == allowedSwapAddress01 || _token == allowedSwapAddress02, "Token not allowed to swap.");

        uint amountToUpgrade = _amount;  
        require(amountToUpgrade <= ERC20(_token).allowance(msg.sender, this));

        uint newBalance = ERC20(_token).balanceOf(msg.sender) - (amountToUpgrade);
        if (ERC20(_token).transferFrom(msg.sender, this, amountToUpgrade)) {

            require(ERC20(_token).balanceOf(msg.sender) == newBalance, "Balance error.");

            if(
              ERC20(allowedSwapAddress01).balanceOf(msg.sender) == 0  &&
              ERC20(allowedSwapAddress02).balanceOf(msg.sender) == 0
            ) {
              hasSwapped[msg.sender] = true;
            }

            tokens[_token][msg.sender] = tokens[_token][msg.sender].add(amountToUpgrade);
            manualSwaps[msg.sender] = amountToUpgrade;
            emit NewSwapRequest(msg.sender, amountToUpgrade);
        }
    }

     
     function getLockedTokens(address _contract, address _holder) public view returns(uint) {
         return CaelumAcceptERC20(_contract).tokens(_contract, _holder);
     }

     
    function approveManualUpgrade(address _holder) onlyOwner public {
        balances[_holder] = balances[_holder].add(manualSwaps[_holder]);
        emit Transfer(this, _holder, manualSwaps[_holder]);
    }

     
    function declineManualUpgrade(address _token, address _holder) onlyOwner public {
        require(ERC20(_token).transfer(_holder, manualSwaps[_holder]));
        tokens[_token][_holder] = tokens[_token][_holder] - manualSwaps[_holder];
        delete manualSwaps[_holder];
        delete hasSwapped[_holder];
    }

     
     function replaceLockedTokens(address _contract, address _holder) onlyOwner public {
         uint amountLocked = getLockedTokens(_contract, _holder);
         balances[_holder] = balances[_holder].add(amountLocked);
         emit Transfer(this, _holder, amountLocked);
         hasSwapped[msg.sender] = true;
     }

     
    function rewardExternal(address _receiver, uint _amount) onlyMiningContract public {
        balances[_receiver] = balances[_receiver].add(_amount);
        emit Transfer(this, _receiver, _amount);
    }

     
    function addToWhitelistExternal(address _token, uint _amount, uint daysAllowed) onlyMasternodeContract public {
        addToWhitelist( _token, _amount, daysAllowed);
    }

     
    function getMiningRewardForPool() public view returns(uint) {
        return masternodeInterface.rewardsProofOfWork();
    }

     
    function rewardsProofOfWork() public view returns(uint) {
        return masternodeInterface.rewardsProofOfWork();
    }

     
    function rewardsMasternode() public view returns(uint) {
        return masternodeInterface.rewardsMasternode();
    }

     
    function masternodeCounter() public view returns(uint) {
        return masternodeInterface.userCounter();
    }

     
    function contractProgress() public view returns
    (
        uint epoch,
        uint candidate,
        uint round,
        uint miningepoch,
        uint globalreward,
        uint powreward,
        uint masternodereward,
        uint usercounter
    )
    {
        return ICaelumMasternode(_contract_masternode()).contractProgress();

    }

     
    function setMasternodeContract() internal  {
        masternodeInterface = ICaelumMasternode(_contract_masternode());
    }

     
    function setModifierContract (address _contract) onlyOwner public {
        require (now <= swapStartedBlock + 10 days);
        _internalMod = InterfaceContracts(_contract);
        setMasternodeContract();
    }

     
    function VoteModifierContract (address _contract) onlyVotingContract external {
         
        _internalMod = InterfaceContracts(_contract);
        setMasternodeContract();
    }
    
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     


}