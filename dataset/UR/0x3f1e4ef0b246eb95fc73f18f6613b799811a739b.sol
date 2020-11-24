 

pragma solidity 0.4.24;

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract DBETToVETDeposit {

    using SafeMath for uint256;

     
    address public dbetTeam;
     
    ERC20 public dbetV1;
     
    ERC20 public dbetV2;

     
    bool public emergencyWithdrawalsEnabled;
     
    bool public finalizedDeposits;
     
    uint256 public depositIndex;

     
     
    mapping(bool => mapping(address => uint256)) public depositedTokens;

    event LogTokenDeposit(
        bool isV2,
        address _address,
        address VETAddress,
        uint256 amount,
        uint256 index
    );
    event LogEmergencyWithdraw(
        bool isV2,
        address _address,
        uint256 amount
    );

    constructor(address v1, address v2) public {
        dbetTeam = msg.sender;
        dbetV1 = ERC20(v1);
        dbetV2 = ERC20(v2);
    }

    modifier isDbetTeam() {
        require(msg.sender == dbetTeam);
        _;
    }

    modifier areWithdrawalsEnabled() {
        require(emergencyWithdrawalsEnabled && !finalizedDeposits);
        _;
    }

     
    function getToken(bool isV2) internal returns (ERC20) {
        if (isV2)
            return dbetV2;
        else
            return dbetV1;
    }

     
    function depositTokens(
        bool isV2,
        uint256 amount,
        address VETAddress
    )
    public {
        require(amount > 0);
        require(VETAddress != 0);
        require(getToken(isV2).balanceOf(msg.sender) >= amount);
        require(getToken(isV2).allowance(msg.sender, address(this)) >= amount);

        depositedTokens[isV2][msg.sender] = depositedTokens[isV2][msg.sender].add(amount);

        require(getToken(isV2).transferFrom(msg.sender, address(this), amount));

        emit LogTokenDeposit(
            isV2,
            msg.sender,
            VETAddress,
            amount,
            depositIndex++
        );
    }

    function enableEmergencyWithdrawals () public
    isDbetTeam {
        emergencyWithdrawalsEnabled = true;
    }

    function finalizeDeposits () public
    isDbetTeam {
        finalizedDeposits = true;
    }

     
    function emergencyWithdraw(bool isV2) public
    areWithdrawalsEnabled {
        require(depositedTokens[isV2][msg.sender] > 0);

        uint256 amount = depositedTokens[isV2][msg.sender];

        depositedTokens[isV2][msg.sender] = 0;

        require(getToken(isV2).transfer(msg.sender, amount));

        emit LogEmergencyWithdraw(isV2, msg.sender, amount);
    }

}