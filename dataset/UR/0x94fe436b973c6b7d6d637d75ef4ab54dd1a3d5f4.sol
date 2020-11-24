 

 
pragma solidity ^0.5.10;

contract TokenERC20 {
    mapping (address => uint256) public balanceOf;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract bountySend{
    uint256 public sentAmount = 0;
    TokenERC20 bcontract;
    
    constructor(address baseAddr) public {
        bcontract = TokenERC20(baseAddr);
    }
    
    function() external payable { 
        revert();
    }
    
    function sendOutToken(address[] memory addrs, uint256[] memory sendAmount) public {
        require(addrs.length >0);
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(sendAmount[i] < 1) continue;
            else{
              bcontract.transferFrom(msg.sender,addrs[i], sendAmount[i] * (10 ** uint256(18)));  
              sentAmount += sendAmount[i];
            } 
        }
    }
    function sendOutTokenWith10digiCorrect(address[] memory addrs, uint256[] memory sendAmount) public {
        require(addrs.length >0);
        for(uint i=0;i<addrs.length;i++){
            if(addrs[i] == address(0)) continue;
            if(sendAmount[i] < 1) continue;
            else{
              bcontract.transferFrom(msg.sender,addrs[i], sendAmount[i] * (10 ** uint256(8)));  
              sentAmount += sendAmount[i];
            } 
        }
    }
}