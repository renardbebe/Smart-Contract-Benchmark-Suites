 

pragma solidity >=0.5.10; 


interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


interface KyberNetworkInterface {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate); 
    function searchBestRate(ERC20 src, ERC20 dest, uint srcAmount, bool usePermissionless) external view returns(address, uint);
}


contract KyberRateTrigger {

    uint public index;
    
    KyberNetworkInterface networkContract = KyberNetworkInterface(0x65897aDCBa42dcCA5DD162c647b1cC3E31238490);
    
    constructor(KyberNetworkInterface _networkContract) public {
        networkContract = _networkContract;
    }
    
    function callGetExpectedRate(ERC20 src, ERC20 dest, uint srcQty) public
        returns (uint expectedRate, uint slippageRate) 
    {
        ++index;
        return networkContract.getExpectedRate(src, dest, srcQty);            
    } 
    
    function callSearchBestRate(ERC20 src, ERC20 dest, uint srcQty, bool usePermissionless) public
        returns(address, uint)
    {
        ++index;
        return networkContract.searchBestRate(src, dest, srcQty, usePermissionless);            
    } 
}