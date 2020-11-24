 

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 

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



 
contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

 

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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.9;

 



contract UltraToken is ERC20Pausable, Ownable {
    using SafeMath for uint256;
 

    string  private _name = "Ultra Token";
    string  private _symbol = "UOS";
    uint8   private _decimals = 4;       

                                            
    uint256 private _deployTime;                 
    uint256 private _month = 30 days;            
    struct VestingContract {
        uint256[]   basisPoints;     
        uint256     startMonth;      
        uint256     endMonth;        
    }

    struct BuyerInfo {
        uint256 total;           
        uint256 claimed;         
        string  contractName;    
    }

    mapping (string => VestingContract) private _vestingContracts;
    mapping (address => BuyerInfo)      private _buyerInfos;

    mapping (address => string) private _keys;               
    mapping (address => bool)   private _updateApproval;     

    constructor() public {
        _mint(address(this), uint256(1000000000).mul(10**uint256(_decimals)));   
        _deployTime = block.timestamp;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function deployTime() public view returns (uint256) {
        return _deployTime;
    }

    function buyerInformation() public view returns (uint256, uint256, string memory) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];
        return (buyerInfo.total, buyerInfo.claimed, buyerInfo.contractName );
    }
    
    function nextVestingDate() public view returns (uint256) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];
        require(buyerInfo.total > 0, "Buyer does not exist");
        VestingContract storage vestingContract = _vestingContracts[buyerInfo.contractName];
        uint256 currentMonth = block.timestamp.sub(_deployTime).div(_month);
        if(currentMonth < vestingContract.startMonth) {
            return _deployTime.add(vestingContract.startMonth.mul(_month));
        } else if(currentMonth >= vestingContract.endMonth) {
            return _deployTime.add(vestingContract.endMonth.mul(_month));
        } else {
            return _deployTime.add(currentMonth.add(1).mul(_month));
        }
    }

    event SetVestingContract(string contractName, uint256[] basisPoints, uint256 startMonth);

    function setVestingContract(string memory contractName, uint256[] memory basisPoints, uint256 startMonth) public onlyOwner whenNotPaused returns (bool) {
        VestingContract storage vestingContract = _vestingContracts[contractName];
        require(vestingContract.basisPoints.length == 0, "can't change an existing contract");
        uint256 totalBPs = 0;
        for(uint256 i = 0; i < basisPoints.length; i++) {
            totalBPs = totalBPs.add(basisPoints[i]);
        }
        require(totalBPs == 10000, "invalid basis points array");  

        vestingContract.basisPoints = basisPoints;
        vestingContract.startMonth  = startMonth;
        vestingContract.endMonth    = startMonth.add(basisPoints.length).sub(1);

        emit SetVestingContract(contractName, basisPoints, startMonth);
        return true;
    }

    event ImportBalance(address[] buyers, uint256[] tokens, string contractName);

     
    function importBalance(address[] memory buyers, uint256[] memory tokens, string memory contractName) public onlyOwner whenNotPaused returns (bool) {
        require(buyers.length == tokens.length, "buyers and balances mismatch");
        
        VestingContract storage vestingContract = _vestingContracts[contractName];
        require(vestingContract.basisPoints.length > 0, "contract does not exist");

        for(uint256 i = 0; i < buyers.length; i++) {
            require(tokens[i] > 0, "cannot import zero balance");
            BuyerInfo storage buyerInfo = _buyerInfos[buyers[i]]; 
            require(buyerInfo.total == 0, "have already imported balance for this buyer");
            buyerInfo.total = tokens[i];
            buyerInfo.contractName = contractName;
        }

        emit ImportBalance(buyers, tokens, contractName);
        return true;
    }

    event Claim(address indexed claimer, uint256 claimed);

    function claim() public whenNotPaused returns (bool) {
        uint256 canClaim = claimableToken();
        
        require(canClaim > 0, "No token is available to claim");

        _buyerInfos[msg.sender].claimed = _buyerInfos[msg.sender].claimed.add(canClaim);
        _transfer(address(this), msg.sender, canClaim);

        emit Claim(msg.sender, canClaim);
        return true;
    }

     
    function claimableToken() public view returns (uint256) {
        BuyerInfo storage buyerInfo = _buyerInfos[msg.sender];

        if(buyerInfo.claimed < buyerInfo.total) {
            VestingContract storage vestingContract = _vestingContracts[buyerInfo.contractName];
            uint256 currentMonth = block.timestamp.sub(_deployTime).div(_month);
            
            if(currentMonth < vestingContract.startMonth) {
                return uint256(0);
            }

            if(currentMonth >= vestingContract.endMonth) {  
                return buyerInfo.total.sub(buyerInfo.claimed);
            } else {
                uint256 claimableIndex = currentMonth.sub(vestingContract.startMonth);
                uint256 canClaim = 0;
                for(uint256 i = 0; i <= claimableIndex; ++i) {
                    canClaim = canClaim.add(vestingContract.basisPoints[i]);
                }
                return canClaim.mul(buyerInfo.total).div(10000).sub(buyerInfo.claimed);
            }
        }
        return uint256(0);
    }

    event SetKey(address indexed buyer, string EOSKey);

    function _register(string memory EOSKey) internal {
        require(bytes(EOSKey).length > 0 && bytes(EOSKey).length <= 64, "EOS public key length should be less than 64 characters");
        _keys[msg.sender] = EOSKey;
  
        emit SetKey(msg.sender, EOSKey);
    }

    function register(string memory EOSKey) public whenNotPaused returns (bool) {
        _register(EOSKey);
        return true;
    }

    function keyOf() public view returns (string memory) {
        return _keys[msg.sender];
    }

    event SetUpdateApproval(address indexed buyer, bool isApproved);

    function setUpdateApproval(address buyer, bool isApproved) public onlyOwner returns (bool) {
        require(balanceOf(buyer) > 0 || _buyerInfos[buyer].total > 0, "This account has no token");  
        _updateApproval[buyer] = isApproved;

        emit SetUpdateApproval(buyer, isApproved);
        return true;
    }

    function updateApproved() public view returns (bool) {
        return _updateApproval[msg.sender];
    }

    function update(string memory EOSKey) public returns (bool) {
        require(_updateApproval[msg.sender], "Need approval from ultra after contract is frozen");
        _register(EOSKey);
        return true;
    }

}