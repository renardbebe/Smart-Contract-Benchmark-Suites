 

pragma solidity ^0.5.1;

interface ERC20Interface {
     function totalSupply() external view returns (uint);
     function balanceOf(address tokenOwner) external view returns (uint balance);
     function allowance(address tokenOwner, address spender) external view returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
}

interface Bancor {
    function convert(ERC20Interface _fromToken, ERC20Interface _toToken, uint256 _amount, uint256 _minReturn) external returns (uint256);
}

contract Experiment {
    ERC20Interface constant public DAI = ERC20Interface(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    ERC20Interface constant public BNT = ERC20Interface(0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C);
    ERC20Interface constant public DAIBNT = ERC20Interface(0xee01b3AB5F6728adc137Be101d99c678938E6E72);
    Bancor         constant public bancor = Bancor(0x587044b74004E3D5eF2D453b7F8d198d9e4cB558);
    
    constructor() public {
        BNT.approve(address(bancor), 1e30);
        DAI.approve(address(bancor), 1e30);        
        DAIBNT.approve(address(bancor), 1e30);        
    }
    
    event StepPre(uint step,
                  uint srcBalanceBefore,
                  uint destBalanceBefore,
                  uint srcAmount);

    event StepPost(uint step,
                   uint srcBalanceAfter,
                   uint destBalanceAfter,
                   uint destAmount);
    
    function step1(uint bntAmount) public returns(uint) {
        emit StepPre(1, BNT.balanceOf(address(bancor)), DAIBNT.totalSupply(), bntAmount);
        
        uint retVal = bancor.convert(BNT, DAIBNT, bntAmount, 1);
        
        emit StepPost(1, BNT.balanceOf(address(bancor)), DAIBNT.totalSupply(), retVal);
        
        return retVal;
    }
    
    function step2(uint daibntAmount) public returns(uint) {
        emit StepPre(2, DAIBNT.totalSupply(), DAI.balanceOf(address(bancor)), daibntAmount);
        
        uint retVal = bancor.convert(DAIBNT, DAI, daibntAmount, 1);
        
        emit StepPost(2, DAIBNT.totalSupply(), DAI.balanceOf(address(bancor)), retVal);
        
        return retVal;
    }
    
    function step3(uint daiAmount) public returns(uint) {
        emit StepPre(3, DAI.balanceOf(address(bancor)), DAIBNT.totalSupply(), daiAmount);
        
        uint retVal = bancor.convert(DAI, DAIBNT, daiAmount, 1);
        
        emit StepPost(3, DAI.balanceOf(address(bancor)), DAIBNT.totalSupply(), retVal);
        
        return retVal;
    }    
    
    function step4(uint daibntAmount) public returns(uint) {
        emit StepPre(4, DAIBNT.totalSupply(), BNT.balanceOf(address(bancor)), daibntAmount);        
        
        uint retVal = bancor.convert(DAIBNT, BNT, daibntAmount, 1);
        
        emit StepPost(4, DAIBNT.totalSupply(), BNT.balanceOf(address(bancor)), retVal);
        
        return retVal;
    }
    
    event AllBalance(uint bntBalance, uint daiBalance, uint daibntBalance);
    
    function allSteps(uint bntAmount) public {
        BNT.transferFrom(msg.sender, address(this), bntAmount);
        
        emit AllBalance(BNT.balanceOf(address(bancor)),
                   DAI.balanceOf(address(bancor)),
                   DAIBNT.totalSupply());
        
        uint amount = step1(bntAmount);
        amount = step2(amount);
        amount = step3(amount);
        amount = step4(amount);
        
        BNT.transfer(msg.sender, amount);
        
        emit AllBalance(BNT.balanceOf(address(bancor)),
                   DAI.balanceOf(address(bancor)),
                   DAIBNT.totalSupply());
    }
}


 