 

pragma solidity ^0.5.11;

contract chainLinkOracleCashout{
    address payable owner;
    
    address constant chainLinkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant dexBlueAddress = 0x000000000000541E251335090AC5B47176AF4f7E;
    
    address oracleAddress;
    address payable arbiterAddress;
    address payable payoutAddress;
    
    uint payoutThreshold      = 1000000000000000000;   
    uint arbiterTargetBalance = 10000000000000000000;  
    uint arbiterRefillBalance = 9000000000000000000;   
    
     
    function() external payable {}
    
    constructor(
        address _oracleAddress,
        address payable _arbiterAddress,
        address payable _payoutAddress
    ) public {
         
        owner = msg.sender;
        
         
        oracleAddress  = _oracleAddress;
        arbiterAddress = _arbiterAddress;
        payoutAddress  = _payoutAddress;
        
         
        Token(chainLinkToken).approve(dexBlueAddress, 2**256 - 1);
    }
    
    function trade(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public payable returns(bool success){
        require(msg.sender == dexBlueAddress);
        
         
        if(
            buy_token != chainLinkToken
            || sell_token != address(0)
        ){
            return false;
        }

        uint linkBalance  = Token(chainLinkToken).balanceOf(address(this));      

         
        if(linkBalance < buy_amount){
            uint withdrawable = Oracle(oracleAddress).withdrawable();            

            if(linkBalance + withdrawable < buy_amount){
                return false;
            }

             
            Oracle(oracleAddress).withdraw(address(this), withdrawable);
        }
 
         
        dexBlue(dexBlueAddress).depositToken(chainLinkToken, buy_amount);
        
         
        payoutIfAboveThreshold();
        
         
        return true;
    }
    
     
    function offer(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public returns(bool accept){
        require(msg.sender == dexBlueAddress);
        
         
        if(
            sell_token   != chainLinkToken
            || buy_token != address(0)
        ){
            return false;
        }

        uint linkBalance  = Token(chainLinkToken).balanceOf(address(this));      

         
        if(linkBalance < sell_amount){
            uint withdrawable = Oracle(oracleAddress).withdrawable();            

            if(linkBalance + withdrawable < sell_amount){
                return false;
            }

             
            Oracle(oracleAddress).withdraw(address(this), withdrawable);
        }
        
         
        dexBlue(dexBlueAddress).depositToken(chainLinkToken, sell_amount);

         
        return true;
    }
    
     
    function offerExecuted(address, uint256, address, uint256) public{
        require(msg.sender == dexBlueAddress);
        
         
        payoutIfAboveThreshold();
    }

     
    function payoutIfAboveThreshold() internal {
         
        uint myBalance      = address(this).balance;
        
        if(myBalance >= payoutThreshold){
             
            uint arbiterBalance = arbiterAddress.balance;
            
             
            if(arbiterBalance <= arbiterRefillBalance){
                uint arbiterPayout = arbiterTargetBalance - arbiterBalance;
                
                if(arbiterPayout > myBalance) arbiterPayout = myBalance;
                
                myBalance -= arbiterPayout;
                arbiterAddress.transfer(arbiterPayout);
            }
            
             
            if(myBalance >= payoutThreshold){
                payoutAddress.transfer(myBalance);
            }
        }
    }
    
    function changePayoutAddress(address payable _payoutAddress) public {
        require(msg.sender == owner);
        
        payoutAddress = _payoutAddress;
    }
    
    function changeArbiterAddress(address payable newArbiterAddress) public {
        require(msg.sender == owner);
        
        arbiterAddress = newArbiterAddress;
    }
    
    function changeArbiterBalances(uint _arbiterTargetBalance, uint _arbiterRefillBalance) public {
        require(
            msg.sender == owner
            && _arbiterTargetBalance > _arbiterRefillBalance
        );
        
        arbiterTargetBalance = _arbiterTargetBalance;
        arbiterRefillBalance = _arbiterRefillBalance;
    }
    
    function changePayoutThreshold(uint _payoutThreshold) public {
        require(msg.sender == owner);
        
        payoutThreshold = _payoutThreshold;
    }
        
    function changeOwner(address payable newOwner) public {
        require(msg.sender == owner);
        
        owner = newOwner;
    }
    
     

    function changeOracleOwnership(address payable newOwner) public {
        require(msg.sender == owner);
        
        Oracle(oracleAddress).transferOwnership(newOwner);
    }
    
    function setOracleFulfillmentPermission(address _node, bool _allowed) public {
        require(msg.sender == owner);
        
        Oracle(oracleAddress).setFulfillmentPermission(_node, _allowed);
    }

     
    
    function approveTokenFor(address token, address spender, uint256 amount) public {
        require(msg.sender == owner);
        
        Token(token).approve(spender, amount);
    }
    
    function withdrawToken(address token, uint256 amount) public {
        require(msg.sender == owner);
        
        require(Token(token).transfer(owner, amount));       
    }
    
    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner);
        
        require(
            owner.send(amount),
            "Sending of ETH failed."
        );
    }
    
    
     
    
     
    function swap(address, uint256, address,  uint256) public payable returns(uint256){
        revert();
    }
    
     
    function getSwapOutput(address, uint256, address) public pure returns(uint256){
        return 0;
    }
    
    function tradeWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory) public payable returns(bool success){
         
        return trade(sell_token, sell_amount, buy_token,  buy_amount);
    }
    
    function offerWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory) public returns(bool accept){
         
        return offer(sell_token, sell_amount, buy_token, buy_amount);
    }
}


contract dexBlue{
    function depositToken(address token, uint256 amount) public {}
    function depositEther() public payable{}
    function getTokens() view public returns(address[] memory){}
}

 
contract dexBlueReserve{
     
    function trade(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public payable returns(bool success){}
    
     
    function tradeWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public payable returns(bool success){}
    
     
    function offer(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public returns(bool accept){}
    
     
    function offerWithData(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount, bytes32[] memory data) public returns(bool accept){}
    
     
    function offerExecuted(address sell_token, uint256 sell_amount, address buy_token,  uint256 buy_amount) public{}

     
    function swap(address sell_token, uint256 sell_amount, address buy_token,  uint256 min_output) public payable returns(uint256 output){}
    
     
    function getSwapOutput(address sell_token, uint256 sell_amount, address buy_token) public view returns(uint256 output){}
}


contract Oracle {
    
    function withdraw(address _recipient, uint256 _amount) public {}
  
    function withdrawable() external view returns (uint256) {}
    
    function transferOwnership(address newOwner) public {}

    function setFulfillmentPermission(address _node, bool _allowed) external {}
}


contract Token {
     
    function totalSupply() view public returns (uint256 supply) {}

     
    function balanceOf(address _owner) view public returns (uint256 balance) {}

     
    function transfer(address _to, uint256 _value) public returns(bool) {}

     
    function transferFrom(address _from, address _to, uint256 _value)  public returns(bool) {}

     
    function approve(address _spender, uint256 _value) public returns(bool)  {}

     
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 public decimals;
    string public name;
}