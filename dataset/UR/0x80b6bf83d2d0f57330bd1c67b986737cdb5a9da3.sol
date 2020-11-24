 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


library ECStructs {

    struct ECDSASig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}

contract ILotteryForCoke {
    struct Ticket {
        address payable ticketAddress;
        uint256 period;
        address payable buyer;
        uint256 amount;
        uint256 salt;
    }

    function buy(Ticket memory ticket, ECStructs.ECDSASig memory serverSig) public returns (bool);

    function calcTicketPrice(Ticket memory ticket) public view returns (uint256 cokeAmount);
}

contract IPledgeForCoke {

    struct DepositRequest {
        address payable depositAddress;
        address payable from;
        uint256 cokeAmount;
        uint256 endBlock;
        bytes32 billSeq;
        bytes32 salt;
    }

     
     
    function deposit(DepositRequest memory request, ECStructs.ECDSASig memory ecdsaSig) payable public returns (bool);

    function depositCheck(DepositRequest memory request, ECStructs.ECDSASig memory ecdsaSig) public view returns (uint256);
}


library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath, mul");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath, div");
         
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath, sub");
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath, add");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath, mod");
        return a % b;
    }
}

contract IRequireUtils {
    function requireCode(uint256 code) external pure;

    function interpret(uint256 code) public pure returns (string memory);
}



interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ReentrancyGuard {

     
    uint256 private _guardCounter;

    constructor() internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "nonReentrant");
    }

}

contract ERC20 is IERC20, ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "ERC20 approve, spender can not be 0x00");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
    function approveFrom(address owner, address spender, uint256 value) internal returns (bool) {
        require(spender != address(0), "ERC20 approveFrom, spender can not be 0x00");

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
        return true;
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        require(value <= _allowed[from][msg.sender], "ERC20 transferFrom, allowance not enough");

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

     
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0), "ERC20 increaseAllowance, spender can not be 0x00");

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }


     
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0), "ERC20 decreaseAllowance, spender can not be 0x00");

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from], "ERC20 _transfer, not enough balance");
        require(to != address(0), "ERC20 _transfer, to address can not be 0x00");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20 _mint, account can not be 0x00");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20 _burn, account can not be 0x00");
        require(value <= _balances[account], "ERC20 _burn, not enough balance");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        require(value <= _allowed[account][msg.sender], "ERC20 _burnFrom, allowance not enough");

         
         
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
            value);
        _burn(account, value);
    }
}

contract Coke is ERC20{
    using SafeMath for uint256;

    IRequireUtils rUtils;

     
    string public name = "COKE";
    string public symbol = "COKE";
    uint256 public decimals = 18;  

    address public cokeAdmin; 
    mapping(address => bool) public gameMachineRecords; 


    uint256 public stagePercent;
    uint256 public step;
    uint256 public remain;
    uint256 public currentDifficulty; 
    uint256 public currentStageEnd;

    address team;
    uint256 public teamRemain;
    uint256 public unlockAllBlockNumber;
    uint256 unlockNumerator;
    uint256 unlockDenominator;

    event Reward(address indexed account, uint256 amount, uint256 rawAmount);
    event UnlockToTeam(address indexed account, uint256 amount, uint256 rawReward);

    constructor (IRequireUtils _rUtils, address _cokeAdmin, uint256 _cap, address _team, uint256 _toTeam,
        uint256 _unlockAllBlockNumber, address _bounty, uint256 _toBounty, uint256 _stagePercent,
        uint256 _unlockNumerator, uint256 _unlockDenominator)  public {
        rUtils = _rUtils;
        cokeAdmin = _cokeAdmin;
        unlockAllBlockNumber = _unlockAllBlockNumber;

        team = _team;
        teamRemain = _toTeam;

        _mint(address(this), _toTeam);

        _mint(_bounty, _toBounty);

        stagePercent = _stagePercent;
        step = _cap * _stagePercent / 100;
        remain = _cap.sub(_toTeam).sub(_toBounty);

        _mint(address(this), remain);

        unlockNumerator = _unlockNumerator;
        unlockDenominator=_unlockDenominator;
        if (remain - step > 0) {
            currentStageEnd = remain - step;
        } else {
            currentStageEnd = 0;
        }
        currentDifficulty = 0;
    }

    function approveAndCall(address spender, uint256 value, bytes memory data) public nonReentrant returns (bool) {
        require(approve(spender, value));

        (bool success, bytes memory returnData) = spender.call(data);
        rUtils.requireCode(success ? 0 : 501);

        return true;
    }

    function approveAndBuyLottery(ILotteryForCoke.Ticket memory ticket, ECStructs.ECDSASig memory serverSig) public nonReentrant returns (bool){
        rUtils.requireCode(approve(ticket.ticketAddress, ILotteryForCoke(ticket.ticketAddress).calcTicketPrice(ticket)) ? 0 : 506);
        rUtils.requireCode(ILotteryForCoke(ticket.ticketAddress).buy(ticket, serverSig) ? 0 : 507);
        return true;
    }

    function approveAndPledgeCoke(IPledgeForCoke.DepositRequest memory depositRequest, ECStructs.ECDSASig memory serverSig) public nonReentrant returns (bool){
        rUtils.requireCode(approve(depositRequest.depositAddress, depositRequest.cokeAmount) ? 0 : 508);
        rUtils.requireCode(IPledgeForCoke(depositRequest.depositAddress).deposit(depositRequest, serverSig) ? 0 : 509);
        return true;
    }

    function betReward(address _account, uint256 _amount) public mintPermission returns (uint256 minted){
        uint256 input = _amount;
        uint256 totalMint = 0;
        while (input > 0) {

            uint256 factor = 2 ** currentDifficulty;
            uint256 discount = input / factor;
            if (input % factor != 0) {
                discount ++;
            }

            if (discount > remain - currentStageEnd) {
                uint256 toMint = remain - currentStageEnd;
                totalMint += toMint;
                input = input - toMint * factor;
                remain = currentStageEnd;
            } else {
                totalMint += discount;
                input = 0;
                remain = remain - discount;
            }

             
            if (remain == currentStageEnd) {
                if (currentStageEnd != 0) {
                    currentDifficulty = currentDifficulty + 1;
                    if (remain - step > 0) {
                        currentStageEnd = remain - step;
                    } else {
                        currentStageEnd = 0;
                    }
                } else {
                    input = 0;
                }
            }
        }
        _transfer(address(this), _account, totalMint);
        emit Reward(_account, totalMint, _amount);

        uint256 mintToTeam = totalMint * unlockDenominator / unlockNumerator;
        if (teamRemain >= mintToTeam) {
            teamRemain = teamRemain - mintToTeam;
            _transfer(address(this), team, mintToTeam);
            emit UnlockToTeam(team, mintToTeam, totalMint);
        }

        return totalMint;
    }

    
    function setGameMachineRecords(address _input, bool _isActivated) public onlyCokeAdmin {
        gameMachineRecords[_input] = _isActivated;
    }

    function unlockAllTeamCoke() public onlyCokeAdmin {
        if (block.number > unlockAllBlockNumber) {
            _transfer(address(this), team, teamRemain);
            teamRemain = 0;
            emit UnlockToTeam(team, teamRemain, 0);
        }
    }

    modifier onlyCokeAdmin(){
        rUtils.requireCode(msg.sender == cokeAdmin ? 0 : 503);
        _;
    }


    modifier mintPermission(){
        rUtils.requireCode(gameMachineRecords[msg.sender] == true ? 0 : 505);
        _;
    }
}