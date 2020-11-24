 

pragma solidity ^0.4.24;


 
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
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
    }
}


 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 
contract Ownable {
    address private _owner;

    event OwnershipSet(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipSet(address(0), _owner);
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
        emit OwnershipSet(_owner, address(0));
        _owner = address(0);
    }
}


 
contract QToken is ERC20, MinterRole, Ownable {

  string public constant name = "QuestCoin";
  string public constant symbol = "QUEST";
  uint public startblock = block.number;
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 0;
  uint256 public constant MAX_SUPPLY = 98000000 * (10 ** uint256(decimals));

}


 
contract ERC20Mintable is QToken {
    uint mintValue;
    uint mintDate;
    uint maxAmount = 2000000 * (10 ** 18);
    uint devMintTimer = 86400;
    uint socialMultiplier = 1;
    event MintingAnnounce(
    uint value,
    uint date
  );
  event PromotionalStageStarted(
    bool promo
  );
  event TransitionalStageStarted(
    bool transition
  );
   event DevEmissionSetLower(uint value);
     
function setMaxDevMintAmount(uint _amount) public onlyOwner returns(bool){
    require(_amount < maxAmount);
    maxAmount = _amount;
    emit DevEmissionSetLower(_amount);
    return(true);
}
      
function setSocialMultiplier (uint _number) public onlyOwner returns(bool){
    require(_number >= 1);
    socialMultiplier = _number;
    return(true);
}

     
 function announceMinting(uint _amount) public onlyMinter{
     require(_amount.add(totalSupply()) < MAX_SUPPLY);
     require(_amount < maxAmount);
      mintDate = block.number;
      mintValue = _amount;
      emit MintingAnnounce(_amount , block.number);
   }

 function AIDmint(
    address to
  )
    public
    onlyMinter
    returns (bool)
  {
      require(mintDate != 0);
    require(block.number.sub(mintDate) > devMintTimer);
      mintDate = 0;
    _mint(to, mintValue);
    mintValue = 0;
    return true;
  }

 function startPromotionalStage() public onlyMinter returns(bool) {
    require(totalSupply() > 70000000 * (10 ** 18));
    devMintTimer = 5760;
    socialMultiplier = 4;
    emit PromotionalStageStarted(true);
    return(true);
}

 function startTransitionalStage() public onlyMinter returns(bool){
    require(totalSupply() > 20000000 * (10 ** 18));
    devMintTimer = 40420;
    socialMultiplier = 2;
    emit TransitionalStageStarted(true);
    return(true);
}}

 
contract QuestContract is ERC20Mintable {

    mapping (address => uint) public karmaSystem;
    mapping (address => uint) public userIncentive;
    mapping (bytes32 => uint) public questReward;
    uint questTimer;
    uint maxQuestReward = 125000;
    uint questPeriodicity = 1;
    event NewQuestEvent(
    uint RewardSize,
    uint DatePosted
   );
    event QuestRedeemedEvent(
    uint WinReward,
    string WinAnswer,
    address WinAddres
  );
    event UserRewarded(
    address UserAdress,
    uint RewardSize
  );
  event MaxRewardDecresed(
    uint amount
  );
  event PeriodicitySet(
    uint amount
  );

     
    function solveQuest (string memory  _quest) public returns (bool){
     require(questReward[keccak256(abi.encodePacked( _quest))] != 0);
    uint _reward = questReward[keccak256(abi.encodePacked( _quest))];
         questReward[keccak256(abi.encodePacked( _quest))] = 0;
         emit QuestRedeemedEvent(_reward,  _quest , msg.sender);
         _mint(msg.sender, _reward);
         karmaSystem[msg.sender] = karmaSystem[msg.sender].add(1);
         if (userIncentive[msg.sender] < _reward){
             userIncentive[msg.sender] = _reward;
         }
         return true;
    }

     
    function joiLittleHelper (string memory test) public pure returns(bytes32){
        return(keccak256(abi.encodePacked(test)));
    }

     
  function createQuest (bytes32 _quest , uint _reward) public onlyMinter returns (bool) {
        require(_reward <= maxQuestReward);
        require(block.number.sub(questTimer) > questPeriodicity);
        _reward = _reward * (10 ** uint256(decimals));
        require(_reward.add(totalSupply()) < MAX_SUPPLY);
        questTimer = block.number;
        questReward[ _quest] = _reward;
        emit NewQuestEvent(_reward, block.number - startblock);
        return true;
    }

      
 function rewardUser (address _user) public onlyMinter returns (bool) {
        require(userIncentive[_user] > 0);
        uint _reward = userIncentive[_user].div(socialMultiplier);
        userIncentive[_user] = 0;
        _mint(_user ,_reward);
        karmaSystem[_user] = karmaSystem[_user].add(1);
        emit UserRewarded(_user ,_reward);
        return true;
    }

      
     function setMaxQuestReward (uint _amount) public onlyOwner returns(bool){
         require(_amount < maxQuestReward);
        maxQuestReward = _amount;
        emit MaxRewardDecresed(_amount);
        return true;
    }
    function setQuestPeriodicity (uint _amount) public onlyOwner returns(bool){
        require(_amount > 240);
        questPeriodicity = _amount;
        emit PeriodicitySet(_amount);
        return true;
    }
}