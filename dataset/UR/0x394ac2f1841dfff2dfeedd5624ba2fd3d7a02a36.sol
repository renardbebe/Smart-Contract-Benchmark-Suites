 

pragma solidity ^0.4.24;

contract GAPS {
 
 
    function transfer(address _to, uint256 _value) public returns (bool success) ;

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

   
}

contract Timelock {
    GAPS token;

    struct LockBoxStruct {
        address beneficiary;
        uint256 balance;
        uint releaseTime;
    }
    uint8 public decimals = 18;
    uint256 changeNum = 10 ** uint256(decimals); 
    
    LockBoxStruct[] public lockBoxStructs; 

    event LogLockBoxDeposit(address sender, uint256 amount, uint releaseTime);   
    event LogLockBoxWithdrawal(address receiver, uint256 amount);

    constructor(address _gaps) public {
        token = GAPS(_gaps);
    }

    function deposit(address beneficiary, uint256 amount, uint releaseTime) public returns(bool success) {
        uint256 _amount = amount * changeNum;
        require(token.transferFrom(msg.sender, address(this), _amount));
        LockBoxStruct memory l;
        l.beneficiary = beneficiary;
        l.balance = amount;
        l.releaseTime = now + releaseTime;
        lockBoxStructs.push(l);
        emit LogLockBoxDeposit(msg.sender, amount, releaseTime);
        return true;
    }

    function withdraw(uint lockBoxNumber) public returns(bool success) {
        LockBoxStruct storage l = lockBoxStructs[lockBoxNumber];
        require(l.beneficiary == msg.sender);
        require(l.releaseTime <=  now);
        uint256 amount = l.balance;
        l.balance = 0;
        emit LogLockBoxWithdrawal(msg.sender, amount);
        uint256 _amount = amount * changeNum;
        require(token.transfer(msg.sender, _amount));
        return true;
    }    
    
    

}