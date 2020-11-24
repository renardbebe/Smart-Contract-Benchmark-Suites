 

 

pragma solidity 0.5.12;

contract DeliverFunds {
    constructor(address payable target) public payable {
        selfdestruct(target);
    }
}

 

pragma solidity 0.5.12;

contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () internal {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 

pragma solidity 0.5.12;

 



contract EthexJackpot is Ownable {
    mapping(uint256 => address payable) public tickets;
    mapping(uint256 => Segment[4]) public prevJackpots;
    uint256[4] public amounts;
    uint256[4] public starts;
    uint256[4] public ends;
    uint256[4] public numberStarts;
    uint256 public numberEnd;
    uint256 public firstNumber;
    uint256 public dailyAmount;
    uint256 public weeklyAmount;
    uint256 public monthlyAmount;
    uint256 public seasonalAmount;
    bool public dailyProcessed;
    bool public weeklyProcessed;
    bool public monthlyProcessed;
    bool public seasonalProcessed;
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexJackpot public previousContract;
    uint256 public dailyNumberStartPrev;
    uint256 public weeklyNumberStartPrev;
    uint256 public monthlyNumberStartPrev;
    uint256 public seasonalNumberStartPrev;
    uint256 public dailyStart;
    uint256 public weeklyStart;
    uint256 public monthlyStart;
    uint256 public seasonalStart;
    uint256 public dailyEnd;
    uint256 public weeklyEnd;
    uint256 public monthlyEnd;
    uint256 public seasonalEnd;
    uint256 public dailyNumberStart;
    uint256 public weeklyNumberStart;
    uint256 public monthlyNumberStart;
    uint256 public seasonalNumberStart;
    uint256 public dailyNumberEndPrev;
    uint256 public weeklyNumberEndPrev;
    uint256 public monthlyNumberEndPrev;
    uint256 public seasonalNumberEndPrev;
    
    struct Segment {
        uint256 start;
        uint256 end;
        bool processed;
    }
    
    event Jackpot (
        uint256 number,
        uint256 count,
        uint256 amount,
        byte jackpotType
    );
    
    event Ticket (
        uint256 number
    );
    
    event Superprize (
        uint256 amount,
        address winner
    );
    
    uint256[4] internal LENGTH = [5000, 35000, 150000, 450000];
    uint256[4] internal PARTS = [84, 12, 3, 1];
    uint256 internal constant PRECISION = 1 ether;
    
    modifier onlyLoto {
        require(msg.sender == lotoAddress, "Loto only");
        _;
    }
    
    function() external payable { }
    
    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        newVersionAddress.transfer(address(this).balance);
    }

    function registerTicket(address payable gamer) external onlyLoto {
        uint256 number = numberEnd + 1;
        for (uint8 i = 0; i < 4; i++) {
            if (block.number >= ends[i]) {
                setJackpot(i);
                numberStarts[i] = number;
            }
            else
                if (numberStarts[i] == prevJackpots[starts[i]][i].start)
                    numberStarts[i] = number;
        }
        numberEnd = number;
        tickets[number] = gamer;
        emit Ticket(number);
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function payIn() external payable {
        uint256 distributedAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        if (distributedAmount < address(this).balance) {
            uint256 amount = (address(this).balance - distributedAmount) / 4;
            amounts[0] += amount;
            amounts[1] += amount;
            amounts[2] += amount;
            amounts[3] += amount;
        }
    }

    function processJackpots(bytes32 hash, uint256[4] memory blockHeights) private {
        uint48 modulo = uint48(bytes6(hash << 29));
        
        uint256[4] memory payAmounts;
        uint256[4] memory wins;
        for (uint8 i = 0; i < 4; i++) {
            if (prevJackpots[blockHeights[i]][i].processed == false && prevJackpots[blockHeights[i]][i].start != 0) {
                payAmounts[i] = amounts[i] * PRECISION / PARTS[i] / PRECISION;
                amounts[i] -= payAmounts[i];
                prevJackpots[blockHeights[i]][i].processed = true;
                wins[i] = getNumber(prevJackpots[blockHeights[i]][i].start, prevJackpots[blockHeights[i]][i].end, modulo);
                emit Jackpot(wins[i], prevJackpots[blockHeights[i]][i].end - prevJackpots[blockHeights[i]][i].start + 1, payAmounts[i], byte(uint8(1) << i));
            }
        }
        
        for (uint8 i = 0; i < 4; i++)
            if (payAmounts[i] > 0 && !getAddress(wins[i]).send(payAmounts[i]))
                (new DeliverFunds).value(payAmounts[i])(getAddress(wins[i]));
    }
    
    function settleJackpot() external {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);
        
        if (block.number == starts[0] || (starts[0] < block.number - 256))
            return;
        
        processJackpots(blockhash(starts[0]), starts);
    }

    function settleMissedJackpot(bytes32 hash, uint256 blockHeight) external onlyOwner {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);
        
        if (blockHeight < block.number - 256)
            processJackpots(hash, [blockHeight, blockHeight, blockHeight, blockHeight]);
    }
    
    function paySuperprize(address payable winner) external onlyLoto {
        uint256 superprizeAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = 0;
        amounts[3] = 0;
        emit Superprize(superprizeAmount, winner);
        if (superprizeAmount > 0 && !winner.send(superprizeAmount))
            (new DeliverFunds).value(superprizeAmount)(winner);
    }
    
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexJackpot(oldAddress);
        starts[0] = previousContract.dailyStart();
        ends[0] = previousContract.dailyEnd();
        prevJackpots[starts[0]][0].processed = previousContract.dailyProcessed();
        starts[1] = previousContract.weeklyStart();
        ends[1] = previousContract.weeklyEnd();
        prevJackpots[starts[1]][1].processed = previousContract.weeklyProcessed();
        starts[2] = previousContract.monthlyStart();
        ends[2] = previousContract.monthlyEnd();
        prevJackpots[starts[2]][2].processed = previousContract.monthlyProcessed();
        starts[3] = previousContract.seasonalStart();
        ends[3] = previousContract.seasonalEnd();
        prevJackpots[starts[3]][3].processed = previousContract.seasonalProcessed();
        prevJackpots[starts[0]][0].start = previousContract.dailyNumberStartPrev();
        prevJackpots[starts[1]][1].start = previousContract.weeklyNumberStartPrev();
        prevJackpots[starts[2]][2].start = previousContract.monthlyNumberStartPrev();
        prevJackpots[starts[3]][3].start = previousContract.seasonalNumberStartPrev();
        numberStarts[0] = previousContract.dailyNumberStart();
        numberStarts[1] = previousContract.weeklyNumberStart();
        numberStarts[2] = previousContract.monthlyNumberStart();
        numberStarts[3] = previousContract.seasonalNumberStart();
        prevJackpots[starts[0]][0].end = previousContract.dailyNumberEndPrev();
        prevJackpots[starts[1]][1].end = previousContract.weeklyNumberEndPrev();
        prevJackpots[starts[2]][2].end = previousContract.monthlyNumberEndPrev();
        prevJackpots[starts[3]][3].end = previousContract.seasonalNumberEndPrev();
        numberEnd = previousContract.numberEnd();        
        amounts[0] = previousContract.dailyAmount();
        amounts[1] = previousContract.weeklyAmount();
        amounts[2] = previousContract.monthlyAmount();
        amounts[3] = previousContract.seasonalAmount();
        firstNumber = numberEnd;
        previousContract.migrate();
    }
    
    function getAddress(uint256 number) public returns (address payable) {
        if (number <= firstNumber)
            return previousContract.getAddress(number);
        return tickets[number];
    }
    
    function setJackpot(uint8 jackpotType) private {
        prevJackpots[ends[jackpotType]][jackpotType].processed = prevJackpots[starts[jackpotType]][jackpotType].end == numberEnd;
        starts[jackpotType] = ends[jackpotType];
        ends[jackpotType] = starts[jackpotType] + LENGTH[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].start = numberStarts[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].end = numberEnd;
    }
    
    function getNumber(uint256 startNumber, uint256 endNumber, uint48 modulo) private pure returns (uint256) {
        return startNumber + modulo % (endNumber - startNumber + 1);
    }
}

 

pragma solidity 0.5.12;

 

 
 contract EthexHouse is Ownable {
    function payIn() external payable { }
    
    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
 }

 

pragma solidity 0.5.12;

 


 
 contract EthexSuperprize is Ownable {
    struct Payout {
        uint256 index;
        uint256 amount;
        uint256 block;
        address payable winnerAddress;
        uint256 betId;
    }
     
    Payout[] public payouts;
    
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexSuperprize public previousContract;
    uint256 public hold;
    
    event Superprize (
        uint256 index,
        uint256 amount,
        address winner,
        uint256 betId,
        byte state
    );
    
    uint8 internal constant PARTS = 6;
    uint256 internal constant PRECISION = 1 ether;
    uint256 internal constant MONTHLY = 150000;

    function() external payable { }
    
    function initSuperprize(address payable winner, uint256 betId) external {
        require(msg.sender == lotoAddress, "Loto only");
        uint256 amount = address(this).balance - hold;
        hold = address(this).balance;
        uint256 sum;
        uint256 temp;
        for (uint256 i = 1; i < PARTS; i++) {
            temp = amount * PRECISION * (i - 1 + 10) / 75 / PRECISION;
            sum += temp;
            payouts.push(Payout(i, temp, block.number + i * MONTHLY, winner, betId));
        }
        payouts.push(Payout(PARTS, amount - sum, block.number + PARTS * MONTHLY, winner, betId));
        emit Superprize(0, amount, winner, betId, 0);
    }
    
    function paySuperprize() external onlyOwner {
        if (payouts.length == 0)
            return;
        Payout[] memory payoutArray = new Payout[](payouts.length);
        uint i = payouts.length;
        while (i > 0) {
            i--;
            if (payouts[i].block <= block.number) {
                emit Superprize(payouts[i].index, payouts[i].amount, payouts[i].winnerAddress, payouts[i].betId, 0x01);
                hold -= payouts[i].amount;
            }
            payoutArray[i] = payouts[i];
            payouts.pop();
        }
        for (i = 0; i < payoutArray.length; i++)
            if (payoutArray[i].block > block.number)
                payouts.push(payoutArray[i]);
        for (i = 0; i < payoutArray.length; i++)
            if (payoutArray[i].block <= block.number && !payoutArray[i].winnerAddress.send(payoutArray[i].amount))
                (new DeliverFunds).value(payoutArray[i].amount)(payoutArray[i].winnerAddress);
    }
     
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexSuperprize(oldAddress);
        lotoAddress = previousContract.lotoAddress();
        hold = previousContract.hold();
        uint256 index;
        uint256 amount;
        uint256 betBlock;
        address payable winner;
        uint256 betId;
        uint256 payoutsCount = previousContract.getPayoutsCount();
        for (uint i = 0; i < payoutsCount; i++) {
            (index, amount, betBlock, winner, betId) = previousContract.payouts(i);
            payouts.push(Payout(index, amount, betBlock, winner, betId));
        }
        previousContract.migrate();
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        require(newVersionAddress != address(0));
        newVersionAddress.transfer(address(this).balance);
    }   

    function getPayoutsCount() public view returns (uint256) { return payouts.length; }
}

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

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

 

pragma solidity ^0.5.0;




 
contract ERC20 is Context, IERC20 {
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
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

     
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 

pragma solidity ^0.5.0;


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
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

 

pragma solidity 0.5.12;






contract EthexFreespins is Ownable, Context, ERC20, ERC20Detailed, MinterRole {

    address payable public lotoAddress;

    constructor () public ERC20Detailed("EthexFreespins", "EFS", 18) { }

    function use(address account, uint256 amount) public {
        require(msg.sender == lotoAddress, "Loto only");
        _burn(account, amount);
        lotoAddress.transfer(amount);
    }

    function setLoto(address payable loto) external onlyOwner {
        lotoAddress = loto;
    }

    function mint(address account, uint256 amount) public payable onlyMinter {
        require(amount == msg.value, 'Mint amount and transfer value must be equal');
        _mint(account, amount);
    }
}

 

pragma solidity ^0.5.0;

contract IUniswapFactory {
     
    address public exchangeTemplate;
    uint256 public tokenCount;
     
    function createExchange(address token) external returns (address exchange);
     
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
     
    function initializeFactory(address template) external;
}

 

pragma solidity ^0.5.0;

contract IUniswapExchange {
     
    function tokenAddress() external view returns (address token);
     
    function factoryAddress() external view returns (address factory);
     
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
     
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
     
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable returns (uint256  tokens_bought);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns (uint256  tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline) external payable returns (uint256  eth_sold);
    function ethToTokenTransferOutput(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256  eth_sold);
     
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256  eth_bought);
    function tokenToEthTransferInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256  eth_bought);
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
    function tokenToEthTransferOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256  tokens_sold);
     
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_bought);
    function tokenToTokenSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address token_addr) external returns (uint256  tokens_sold);
    function tokenToTokenTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address token_addr) external returns (uint256  tokens_sold);
     
    function tokenToExchangeSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeTransferInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_bought);
    function tokenToExchangeSwapOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address exchange_addr) external returns (uint256  tokens_sold);
    function tokenToExchangeTransferOutput(uint256 tokens_bought, uint256 max_tokens_sold, uint256 max_eth_sold, uint256 deadline, address recipient, address exchange_addr) external returns (uint256  tokens_sold);
     
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
     
    function setup(address token_addr) external;
}

 

pragma solidity 0.5.12;

 










contract EthexLoto is Ownable {
    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        uint256 id;
        bytes6 bet;
        address payable gamer;
    }

    struct Transaction {
        uint256 amount;
        address payable gamer;
    }

    struct Superprize {
        uint256 amount;
        uint256 id;
    }

    mapping(uint256 => uint256) public blockNumberQueue;
    mapping(uint256 => uint256) public amountQueue;
    mapping(uint256 => uint256) public idQueue;
    mapping(uint256 => bytes6) public betQueue;
    mapping(uint256 => address payable) public gamerQueue;
    uint256 public first = 2;
    uint256 public last = 1;
    uint256 public holdBalance;
    uint256 public betCount;

    address payable public newVersionAddress;
    address payable public jackpotAddress;
    address payable public houseAddress;
    address payable public superprizeAddress;
    address payable public freespinsAddress;
    address payable public uniswapAddress;

    event TokenBetAdded (
        uint256 tokenAmount,
        uint256 ethAmount
    );
    
    event PlaceBet (
        uint256 id
    );

    event PayoutBet (
        uint256 amount,
        uint256 id,
        address gamer
    );

    event RefundBet (
        uint256 amount,
        uint256 id,
        address gamer
    );

    uint256 internal constant MIN_BET = 0.01 ether;
    uint256 internal constant PRECISION = 1 ether;
    uint256 internal constant JACKPOT_PERCENT = 10;
    uint256 internal constant HOUSE_EDGE = 10;

    constructor(address payable jackpot, address payable house, address payable superprize, address payable freespins, address payable uniswap) public {
        jackpotAddress = jackpot;
        houseAddress = house;
        superprizeAddress = superprize;
        freespinsAddress = freespins;
        uniswapAddress = uniswap;
    }

    function() external payable { }

    function placeTokenBet(address tokenAddress, uint256 betMaxTokenAmount, uint256 betTargetEthAmount, uint256 swapDeadline, bytes6 bet) external {
        require(betTargetEthAmount >= MIN_BET, "Bet amount should be greater or equal than minimal amount");
        require(tokenAddress != address(0), "Token address is required");

        if (tokenAddress == freespinsAddress)
        {
            placeFreespinBet(betTargetEthAmount, bet);
            return;
        }

        IERC20 token = IERC20(tokenAddress);
        IUniswapFactory uniswapFactory = IUniswapFactory(uniswapAddress);

        address exchangeAddress = uniswapFactory.getExchange(tokenAddress);
        require(exchangeAddress != address(0), "Token is not supported");

        IUniswapExchange uniswap = IUniswapExchange(exchangeAddress);

        uint256 tokensSold = uniswap.getTokenToEthOutputPrice(betTargetEthAmount);
        require(betMaxTokenAmount >= tokensSold, "Swap requires more token then was allowed");

        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= tokensSold, "Not enough tokens");

        token.transferFrom(msg.sender, address(this), tokensSold);
        token.approve(exchangeAddress, tokensSold);

        uint256 converted = uniswap.tokenToEthSwapOutput(betTargetEthAmount, tokensSold, swapDeadline);
        require(converted >= betTargetEthAmount, "Exchange result is smaller then requested");

        placeBet(msg.sender, betTargetEthAmount, bet);

        emit TokenBetAdded(tokensSold, betTargetEthAmount);
    }

    function placeFreespinBet(uint256 betAmount, bytes6 bet) public {
        require(betAmount >= MIN_BET, "Bet amount should be greater or equal than minimal amount");

        EthexFreespins token = EthexFreespins(freespinsAddress);
        uint256 balance = token.balanceOf(msg.sender);

        require(balance >= betAmount, "Not enough tokens");

        token.use(msg.sender, betAmount);

        placeBet(msg.sender, betAmount, bet);

        emit TokenBetAdded(betAmount, betAmount);
    }

    function placeBet(bytes6 bet) external payable {
        require(tx.origin == msg.sender);

        placeBet(msg.sender, msg.value, bet);
    }

    function placeBet(address payable player, uint256 amount, bytes6 bet) private {
        require(amount >= MIN_BET, "Bet amount should be greater or equal than minimal amount");

        uint256 coefficient;
        uint8 markedCount;
        uint256 holdAmount;
        uint256 jackpotFee = amount * JACKPOT_PERCENT * PRECISION / 100 / PRECISION;
        uint256 houseEdgeFee = amount * HOUSE_EDGE * PRECISION / 100 / PRECISION;
        uint256 betAmount = amount - jackpotFee - houseEdgeFee;

        (coefficient, markedCount, holdAmount) = getHold(betAmount, bet);

        require(amount * (100 - JACKPOT_PERCENT - HOUSE_EDGE) * (coefficient * 8 - 15 * markedCount) <= 9000 ether * markedCount);

        require(
            amount * (800 * coefficient - (JACKPOT_PERCENT + HOUSE_EDGE) * (coefficient * 8 + 15 * markedCount)) <= 1500 * markedCount * (address(this).balance - holdBalance));

        betCount++;

        holdBalance += holdAmount;

        enqueue(block.number, betAmount, betCount, bet, player);
        
        emit PlaceBet(betCount);

        if (markedCount > 1)
            EthexJackpot(jackpotAddress).registerTicket(player);

        EthexHouse(houseAddress).payIn.value(houseEdgeFee)();
        EthexJackpot(jackpotAddress).payIn.value(jackpotFee)();
    }

    function settleBets() external {
        if (first > last)
            return;
        uint256 i = 0;
        uint256 length = getLength();
        length = length > 10 ? 10 : length;
        Transaction[] memory transactions = new Transaction[](length);
        Superprize[] memory superprizes = new Superprize[](length);
        uint256 balance = address(this).balance - holdBalance;

        for(; i < length; i++) {
            if (blockNumberQueue[first] >= block.number) {
                length = i;
                break;
            }
            else {
                Bet memory bet = dequeue();
                uint256 coefficient = 0;
                uint8 markedCount = 0;
                uint256 holdAmount = 0;
                (coefficient, markedCount, holdAmount) = getHold(bet.amount, bet.bet);
                holdBalance -= holdAmount;
                balance += holdAmount;
                if (bet.blockNumber < block.number - 256) {
                    transactions[i] = Transaction(bet.amount, bet.gamer);
                    emit RefundBet(bet.amount, bet.id, bet.gamer);
                    balance -= bet.amount;
                }
                else {
                    bytes32 blockHash = blockhash(bet.blockNumber);
                    coefficient = 0;
                    uint8 matchesCount;
                    bool isSuperPrize = true;
                    for (uint8 j = 0; j < bet.bet.length; j++) {
                        if (bet.bet[j] > 0x13) {
                            isSuperPrize = false;
                            continue;
                        }
                        byte field;
                        if (j % 2 == 0)
                            field = blockHash[29 + j / 2] >> 4;
                        else
                            field = blockHash[29 + j / 2] & 0x0F;
                        if (bet.bet[j] < 0x10) {
                            if (field == bet.bet[j]) {
                                matchesCount++;
                                coefficient += 30;
                            }
                            else
                                isSuperPrize = false;
                            continue;
                        }
                        else
                            isSuperPrize = false;
                        if (bet.bet[j] == 0x10) {
                            if (field > 0x09 && field < 0x10) {
                                matchesCount++;
                                coefficient += 5;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x11) {
                            if (field < 0x0A) {
                                matchesCount++;
                                coefficient += 3;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x12) {
                            if (field < 0x0A && field & 0x01 == 0x01) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x13) {
                            if (field < 0x0A && field & 0x01 == 0x0) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                    }

                    coefficient *= PRECISION * 8;
                        
                    uint256 payoutAmount = bet.amount * coefficient / (PRECISION * 15 * markedCount);
                    transactions[i] = Transaction(payoutAmount, bet.gamer);
                    emit PayoutBet(payoutAmount, bet.id, bet.gamer);
                    balance -= payoutAmount;

                    if (isSuperPrize == true) {
                        superprizes[i].amount = balance;
                        superprizes[i].id = bet.id;
                        balance = 0;
                    }
                }
            }
        }

        for (i = 0; i < length; i++) {
            if (transactions[i].amount > 0 && !transactions[i].gamer.send(transactions[i].amount))
                (new DeliverFunds).value(transactions[i].amount)(transactions[i].gamer);
            if (superprizes[i].id != 0) {
                EthexSuperprize(superprizeAddress).initSuperprize(transactions[i].gamer, superprizes[i].id);
                EthexJackpot(jackpotAddress).paySuperprize(transactions[i].gamer);
                if (superprizes[i].amount > 0 && !transactions[i].gamer.send(superprizes[i].amount))
                    (new DeliverFunds).value(superprizes[i].amount)(transactions[i].gamer);
            }
        }
    }

    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        require(getLength() == 0, "There are pending bets");
        require(newVersionAddress != address(0), "NewVersionAddress required");
        newVersionAddress.transfer(address(this).balance);
    }

    function setJackpot(address payable jackpot) external onlyOwner {
        jackpotAddress = jackpot;
    }

    function setSuperprize(address payable superprize) external onlyOwner {
        superprizeAddress = superprize;
    }

    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }

    function setOldVersion(address payable oldAddress) external onlyOwner {
        EthexLoto(oldAddress).migrate();
    }

    function withdrawToken(IERC20 token, uint amount, address sendTo) external onlyOwner {
        require(token.transfer(sendTo, amount));
    }

    function setBetCount(uint256 startBetCount) external onlyOwner { betCount = startBetCount; }

    function length() external view returns (uint256) { return getLength(); }

    function enqueue(uint256 blockNumber, uint256 amount, uint256 id, bytes6 bet, address payable gamer) internal {
        last += 1;
        blockNumberQueue[last] = blockNumber;
        amountQueue[last] = amount;
        idQueue[last] = id;
        betQueue[last] = bet;
        gamerQueue[last] = gamer;
    }

    function dequeue() internal returns (Bet memory bet) {
        require(last >= first);

        bet = Bet(blockNumberQueue[first], amountQueue[first], idQueue[first], betQueue[first], gamerQueue[first]);

        delete blockNumberQueue[first];
        delete amountQueue[first];
        delete idQueue[first];
        delete betQueue[first];
        delete gamerQueue[first];

        if (first == last) {
            first = 2;
            last = 1;
        }
        else
            first += 1;
    }
    
    function getLength() internal view returns (uint256) {
        return 1 + last - first;
    }
    
    function getHold(uint256 amount, bytes6 bet) internal pure returns (uint256 coefficient, uint8 markedCount, uint256 holdAmount) {
        for (uint8 i = 0; i < bet.length; i++) {
            if (bet[i] > 0x13)
                continue;
            markedCount++;
            if (bet[i] < 0x10) {
                coefficient += 30;
                continue;
            }
            if (bet[i] == 0x10) {
                coefficient += 5;
                continue;
            }
            if (bet[i] == 0x11) {
                coefficient += 3;
                continue;
            }
            if (bet[i] == 0x12) {
                coefficient += 6;
                continue;
            }
            if (bet[i] == 0x13) {
                coefficient += 6;
                continue;
            }
        }
        holdAmount = amount * coefficient * 8 / 15 / markedCount;
    }
}