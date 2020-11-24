 

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

contract IRequireUtils {
    function requireCode(uint256 code) external pure;

     
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

contract ERC20 is IERC20 {
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}
contract Coke is ERC20 {
    using SafeMath for uint256;

    IRequireUtils internal rUtils;

     
    string public name = "CB";
    string public symbol = "CB";
    uint256 public decimals = 18;  

    address public cokeAdmin; 
    mapping(address => bool) public gameMachineRecords; 

    uint256 public step;
    uint256 public remain;
    uint256 public currentDifficulty; 
    uint256 public currentStageEnd;

    address internal team;
    uint256 public teamRemain;
    uint256 public unlockAllBlockNumber;
     
    uint256 internal unlockNumerator;
    uint256 internal unlockDenominator;

    event Reward(address indexed account, uint256 amount, uint256 rawAmount);
    event UnlockToTeam(address indexed account, uint256 amount, uint256 rawReward);
    event PermitGameMachine(address indexed gameMachineAddress, bool approved);


    constructor (IRequireUtils _rUtils, address _cokeAdmin, address _team, uint256 _unlockAllBlockNumber, address _bounty) public {
        rUtils = _rUtils;
        cokeAdmin = _cokeAdmin;

        require(_cokeAdmin != address(0));
        require(_team != address(0));
        require(_bounty != address(0));

        unlockAllBlockNumber = _unlockAllBlockNumber;
        uint256 cap = 8000000000000000000000000000;
        team = _team;
        teamRemain = 1600000000000000000000000000;

        _mint(address(this), 1600000000000000000000000000);
        _mint(_bounty, 800000000000000000000000000);

        step = cap.mul(5).div(100);
        remain = cap.sub(teamRemain).sub(800000000000000000000000000);

        _mint(address(this), remain);

         
        unlockNumerator = 7;
        unlockDenominator = 2;
        if (remain.sub(step) > 0) {
            currentStageEnd = remain.sub(step);
        } else {
            currentStageEnd = 0;
        }
        currentDifficulty = 0;
    }

     
    function betReward(address _account, uint256 _amount) public mintPermission returns (uint256 minted){
        if (remain == 0) {
            return 0;
        }

        uint256 input = _amount;
        uint256 totalMint = 0;
        while (input > 0) {

            uint256 factor = 2 ** currentDifficulty;
            uint256 discount = input.div(factor);
             
            if (input.mod(factor) != 0) {
                discount = discount.add(1);
            }

            if (discount > remain.sub(currentStageEnd)) {
                uint256 toMint = remain.sub(currentStageEnd);
                totalMint = totalMint.add(toMint);
                input = input.sub(toMint.mul(factor));
                 
                remain = currentStageEnd;
            } else {
                totalMint = totalMint.add(discount);
                input = 0;
                remain = remain.sub(discount);
            }

             
            if (remain <= currentStageEnd) {
                if (currentStageEnd != 0) {
                    currentDifficulty = currentDifficulty.add(1);
                    if (remain.sub(step) > 0) {
                        currentStageEnd = remain.sub(step);
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

         
        uint256 mintToTeam = totalMint.mul(unlockDenominator).div(unlockNumerator);
        if (teamRemain >= mintToTeam) {
            teamRemain = teamRemain.sub(mintToTeam);
             
            _transfer(address(this), team, mintToTeam);
            emit UnlockToTeam(team, mintToTeam, totalMint);
        } else {
            mintToTeam = teamRemain;
            teamRemain = 0;
            _transfer(address(this), team, mintToTeam);
            emit UnlockToTeam(team, mintToTeam, totalMint);
        }

        return totalMint;
    }

    function activateGameMachine(address _input) public onlyCokeAdmin {
        gameMachineRecords[_input] = true;
        emit PermitGameMachine(_input, true);
    }

    function deactivateGameMachine(address _input) public onlyCokeAdmin {
        gameMachineRecords[_input] = false;
        emit PermitGameMachine(_input, false);
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