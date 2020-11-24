 

pragma solidity >=0.5.0;

contract ERC20{
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
 
 
 
contract Staking{

    address payable userAddress;
    uint totalStakingEtherAmt;
    uint totalStakingTetherAmt;
    uint totalWithdrawEtherAmt;
    uint totalWithdrawTetherAmt;
    bool isValid;
    
    address tether_0x_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    string  identifier = "0x8f3f154ad4469b340065df087275b43fa7cd7ab2";
    address public owner;
    ERC20 tetherContract;

    modifier onlyOwner {
        require(msg.sender == owner,"invalid sender");
        _;
    }

    event EtherStaking(address indexed addr, uint amount);
    event TetherStaking(address indexed addr, uint amount);
    event Withdrawal(address indexed addr, uint indexed _type , uint amount);
    event Refund(address indexed addr);

    constructor() public {
        owner = msg.sender;
        tetherContract =  ERC20(tether_0x_address);
    }

    function () external payable{
        revert();
    }

    function stakeEther() public payable returns(bool){
        address payable addr = msg.sender;
        uint amount = msg.value;
        require(amount > 0, "invalid amount");
        if(isValid){
            require(msg.sender == userAddress, "invalid sender");
            totalStakingEtherAmt += amount;
        }else{
            userAddress = addr;
            totalStakingEtherAmt = amount;
            totalStakingTetherAmt = 0;
            totalWithdrawEtherAmt = 0;
            totalWithdrawTetherAmt = 0;
            isValid = true;
        }
        emit EtherStaking(addr, amount);
        return true;
    }

    function stakeTether(uint amount) public returns(bool){
        require(amount > 0, "invalid amount");
        tetherContract.transferFrom(msg.sender,address(this),amount);
        if(isValid){
            require(msg.sender == userAddress, "invalid sender");
            totalStakingTetherAmt += amount;
            
        }else{
            userAddress = msg.sender;
            totalStakingEtherAmt = 0;
            totalStakingTetherAmt = amount;
            totalWithdrawEtherAmt = 0;
            totalWithdrawTetherAmt = 0;
            isValid = true;
        }
        emit TetherStaking(msg.sender, amount);
        return true;
    }

    function withdraw(uint amount,uint _type) public returns(bool){
        address addr = msg.sender;
        require(amount > 0,"invalid amount");
        require(addr == userAddress, "invalid sender");

        if(_type == 1){
            require(totalStakingEtherAmt - totalWithdrawEtherAmt >= amount, "not enough balance");
            totalWithdrawEtherAmt += amount;
            userAddress.transfer(amount);
            emit Withdrawal(addr, _type, amount);
            return true;
        }
        if(_type == 2){
            require(totalStakingTetherAmt - totalWithdrawTetherAmt >= amount, "not enough balance");
            totalWithdrawTetherAmt += amount;
            tetherContract.transfer(msg.sender, amount);
            emit Withdrawal(addr, _type, amount);
            return true;
        }
        return false;

    }

    function refund() public onlyOwner returns(bool){
        if(isValid){
            uint etherAmt = totalStakingEtherAmt - totalWithdrawEtherAmt;
            uint tetherAmt = totalStakingTetherAmt - totalWithdrawTetherAmt;

            if(etherAmt>0){
                userAddress.transfer(etherAmt);
                totalWithdrawEtherAmt += etherAmt;
            }
            if(tetherAmt>0){
                tetherContract.transfer(userAddress, tetherAmt);
                totalWithdrawTetherAmt +=tetherAmt;
            }
            emit Refund(userAddress);
            return true;
        }
        return false;
    }

    function getBalanceOf() public view returns(uint,uint,uint,uint,uint,uint){
        return (totalStakingEtherAmt - totalWithdrawEtherAmt, totalStakingTetherAmt - totalWithdrawTetherAmt, totalStakingEtherAmt, totalStakingTetherAmt, totalWithdrawEtherAmt, totalWithdrawTetherAmt);
    }

}