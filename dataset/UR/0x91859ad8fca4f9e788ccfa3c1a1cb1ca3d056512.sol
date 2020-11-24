 

 

 

 

 

 

 

 

pragma solidity ^0.5.11;

contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
     function balanceOf(address account) external view returns(uint256);
     function allowance(address _owner, address _spender)external view returns(uint256);
}

library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract StableDEX {
    using SafeMath for uint256;
    
    event DepositandWithdraw(address from,address tokenAddress,uint256 amount,uint256 type_);  
    
    address payable admin;
    
    address public feeAddress;
    
    bool private dexStatus;   
      
    uint256 public tokenId=0;
      
    struct orders{
        address userAddress;
        address tokenAddress;
        uint256 type_;
        uint256 price;
        uint256 total;
        uint256 _decimal;
        uint256 tradeTotal;
        uint256 amount;
        uint256 tradeAmount;
        uint256 pairOrderID;
        uint256 status; 
    }
    
    struct tokens{
        address tokenAddress;
        string tokenSymbol;
        uint256 decimals;
        bool status;
    }
    
    
    constructor(address payable _admin,address feeAddress_) public{
        admin = _admin;
        feeAddress = feeAddress_;
        dexStatus = true;
    }

    
    mapping(uint256=>orders) public Order;  
    
    mapping(address=>mapping(address=>uint256))public userDetails;   
    
    mapping(address=>mapping(address=>uint256))public feeAmount;
    
     mapping(address=>uint256) public withdrawfee;
     
     mapping(uint256=>mapping(uint256=>bool)) public orderPairStatus;
     
     mapping(address=>tokens) public tokendetails;
    
    modifier dexstatuscheck(){
       require(dexStatus==true);
       _;
    }
    
    function setDexStatus(bool status_) public returns(bool){
        require(msg.sender == admin);
        dexStatus = status_;
        return true;
    }   
    
    function addToken(address tokenAddress,string memory tokenSymbol,uint256 decimal_) public returns(bool){
        require(msg.sender == feeAddress && tokendetails[tokenAddress].status==false);
        tokendetails[tokenAddress].tokenSymbol=tokenSymbol;
        tokendetails[tokenAddress].decimals=decimal_;
        tokendetails[tokenAddress].status=true;
        return true;
    }
    
    function deposit() dexstatuscheck public payable returns(bool) {
        require(msg.value > 0);
        userDetails[msg.sender][address(0)]=userDetails[msg.sender][address(0)].add(msg.value);
        emit DepositandWithdraw( msg.sender, address(0),msg.value,0);
        return true;
    }
    
    function tokenDeposit(address tokenaddr,uint256 tokenAmount) dexstatuscheck public returns(bool)
    {
        require(tokenAmount > 0 && tokendetails[tokenaddr].status==true);
        require(tokenallowance(tokenaddr,msg.sender) > 0);
        userDetails[msg.sender][tokenaddr] = userDetails[msg.sender][tokenaddr].add(tokenAmount);
        Token(tokenaddr).transferFrom(msg.sender,address(this), tokenAmount);
        emit DepositandWithdraw( msg.sender,tokenaddr,tokenAmount,0);
        return true;
        
    }
  
    function withdraw(uint8 type_,address tokenaddr,uint256 amount) dexstatuscheck public returns(bool) {
        require(type_ ==0 || type_ == 1);
         if(type_==0){  
         require(tokenaddr == address(0));
         require(amount>0 && amount <= userDetails[msg.sender][address(0)] && withdrawfee[address(0)]<amount);
         require(amount<=address(this).balance);
                msg.sender.transfer(amount.sub(withdrawfee[address(0)]));    
                userDetails[msg.sender][address(0)] = userDetails[msg.sender][address(0)].sub(amount);
                feeAmount[admin][address(0)] = feeAmount[admin][address(0)].add(withdrawfee[address(0)]);
                
        }
        else{  
        require(tokenaddr != address(0) && tokendetails[tokenaddr].status==true);
        require(amount>0 && amount <= userDetails[msg.sender][tokenaddr] && withdrawfee[tokenaddr]<amount);
              Token(tokenaddr).transfer(msg.sender, (amount.sub(withdrawfee[tokenaddr])));
              userDetails[msg.sender][tokenaddr] = userDetails[msg.sender][tokenaddr].sub(amount);
              feeAmount[admin][tokenaddr] = feeAmount[admin][tokenaddr].add(withdrawfee[tokenaddr]);
        }
        emit DepositandWithdraw( msg.sender,tokenaddr,amount,1);
        return true;
    }

     function adminProfitWithdraw(uint8 type_,address tokenAddr)public returns(bool){  
       require(msg.sender == admin);
       require(type_ ==0 || type_ == 1);
         if(type_==0){  
            admin.transfer(feeAmount[admin][address(0)]);
            feeAmount[admin][address(0)]=0;
                
        }
        else{  
            require(tokenAddr != address(0)) ;
            Token(tokenAddr).transfer(admin, feeAmount[admin][tokenAddr]);
            feeAmount[admin][tokenAddr]=0;
        }
           
          
            return true;
        }
        
        
    function setwithdrawfee(address[] memory addr,uint256[] memory feeamount)public returns(bool)
        {
          require(msg.sender==admin);
           
          require(addr.length <10 && feeamount.length < 10 && addr.length==feeamount.length);
          for(uint8 i=0;i<addr.length;i++){
            withdrawfee[addr[i]]=feeamount[i];    
          }
           return true;
        }
    

    
    function verify(string memory  message, uint8 v, bytes32 r, bytes32 s) private pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000; 
        while (divisor != 0) {
            uint256 digit = length.div(divisor);
            if (digit == 0) {
             
                if (lengthLength == 0) {
                      divisor = divisor.div(10);
                      continue;
                    }
            }
            lengthLength++;
            length = length.sub(digit.mul(divisor));
            divisor = divisor.div(10);
            digit = digit.add(0x30);
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }  
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength = lengthLength.add(1 + 0x19);
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }
            
            
 
    
    
     function makeOrder(uint256[9] memory tradeDetails,address[2] memory traderAddresses,string memory message,uint8  v,bytes32 r,bytes32 s) dexstatuscheck public returns(bool){
      require(msg.sender == feeAddress);
       require(verify((message),v,r,s)==traderAddresses[1]);
        
      
     
       
       
       
       
       
       
       
       
       

 
     
       
       
    
    
      uint256 amount__;
       
        uint256 orderiD = tradeDetails[0];
        if(Order[orderiD].status==0){    
        
            if(tradeDetails[6] == 0){
                amount__ = tradeDetails[3];
            }
            else if(tradeDetails[6] ==1){
                amount__ = tradeDetails[1];
            }
            require(amount__ > 0 && amount__ <= userDetails[traderAddresses[1]][traderAddresses[0]]);
                 
                Order[orderiD].userAddress = traderAddresses[1];
                Order[orderiD].type_ = tradeDetails[6];
                Order[orderiD].price = tradeDetails[2];
                Order[orderiD].amount  = tradeDetails[1];
                Order[orderiD].total  = tradeDetails[3];
                Order[orderiD].tradeTotal  = tradeDetails[3];
                Order[orderiD]._decimal  = tradeDetails[7];
                Order[orderiD].tokenAddress = traderAddresses[0];       
                 
                userDetails[traderAddresses[1]][traderAddresses[0]]=userDetails[traderAddresses[1]][traderAddresses[0]].sub(amount__);
                 
                Order[orderiD].tradeAmount=tradeDetails[1];
                Order[orderiD].status=1;
            
        }
        else if(Order[orderiD].status==1 && tradeDetails[8]==0){  
            cancelOrder(orderiD);
        }
        if(Order[orderiD].status==1 && tradeDetails[1] > 0 && tradeDetails[8]>0 && Order[tradeDetails[8]].status==1 && tradeDetails[3]>0){  
                
                Order[orderiD].tradeAmount =Order[orderiD].tradeAmount.sub(tradeDetails[1]);
                Order[tradeDetails[8]].tradeAmount =Order[tradeDetails[8]].tradeAmount.sub(tradeDetails[1]);
                if(tradeDetails[2]>0){
                    userDetails[Order[orderiD].userAddress][Order[orderiD].tokenAddress]=userDetails[Order[orderiD].userAddress][Order[orderiD].tokenAddress].add(tradeDetails[2]);
                }
                Order[orderiD].tradeTotal =Order[orderiD].tradeTotal.sub(((tradeDetails[1].mul(Order[orderiD].price)).div(Order[orderiD]._decimal)));
                Order[tradeDetails[8]].tradeTotal =Order[tradeDetails[8]].tradeTotal.sub(((tradeDetails[1].mul(Order[tradeDetails[8]].price)).div(Order[tradeDetails[8]]._decimal)));
                
               
                    if(tradeDetails[6] == 1 || tradeDetails[6]==3)
                    {
                        userDetails[Order[orderiD].userAddress][Order[tradeDetails[8]].tokenAddress]=userDetails[Order[orderiD].userAddress][Order[tradeDetails[8]].tokenAddress].add(tradeDetails[1]);
                        userDetails[Order[orderiD].userAddress][traderAddresses[0]]= userDetails[Order[orderiD].userAddress][traderAddresses[0]].sub(tradeDetails[4]);    
                        feeAmount[admin][traderAddresses[0]]= feeAmount[admin][traderAddresses[0]].add(tradeDetails[4]);
                    }
                    else
                    {
                         userDetails[Order[orderiD].userAddress][Order[tradeDetails[8]].tokenAddress]=userDetails[Order[orderiD].userAddress][Order[tradeDetails[8]].tokenAddress].add(tradeDetails[1].sub(tradeDetails[4]));
                            feeAmount[admin][Order[tradeDetails[8]].tokenAddress]= feeAmount[admin][Order[tradeDetails[8]].tokenAddress].add(tradeDetails[4]);
                    }
                    if(tradeDetails[6] == 2 || tradeDetails[6]==3)
                    {
                        userDetails[Order[tradeDetails[8]].userAddress][Order[orderiD].tokenAddress]=userDetails[Order[tradeDetails[8]].userAddress][Order[orderiD].tokenAddress].add(tradeDetails[3]);
                        userDetails[Order[tradeDetails[8]].userAddress][traderAddresses[0]]= userDetails[Order[tradeDetails[8]].userAddress][traderAddresses[0]].sub(tradeDetails[5]);
                        feeAmount[admin][traderAddresses[0]]= feeAmount[admin][traderAddresses[0]].add(tradeDetails[5]);
                    }
                    else
                    {
                         userDetails[Order[tradeDetails[8]].userAddress][Order[orderiD].tokenAddress]=userDetails[Order[tradeDetails[8]].userAddress][Order[orderiD].tokenAddress].add(tradeDetails[3].sub(tradeDetails[5]));
                         feeAmount[admin][Order[orderiD].tokenAddress]= feeAmount[admin][Order[orderiD].tokenAddress].add(tradeDetails[5]);
                    }
              
                
                if(Order[tradeDetails[8]].tradeAmount==0){
                    Order[tradeDetails[8]].status=2;    
                }
                if(Order[orderiD].tradeAmount==0){
                    Order[orderiD].status=2;    
                }
                orderPairStatus[orderiD][tradeDetails[8]] = true;
            }

        return true; 
    }

    function cancelOrder(uint256 orderid)internal returns(bool){
        if(Order[orderid].status==1){
            if(Order[orderid].type_ == 0){
            userDetails[ Order[orderid].userAddress][Order[orderid].tokenAddress]=userDetails[ Order[orderid].userAddress][Order[orderid].tokenAddress].add(Order[orderid].tradeTotal);        
            }
            else{
                userDetails[ Order[orderid].userAddress][Order[orderid].tokenAddress]=userDetails[ Order[orderid].userAddress][Order[orderid].tokenAddress].add(Order[orderid].tradeAmount);
            }
            Order[orderid].status=3;     
        }
        return true;
}
    
    
     function viewTokenBalance(address tokenAddr,address baladdr)public view returns(uint256){
        return Token(tokenAddr).balanceOf(baladdr);
    }
    
    function tokenallowance(address tokenAddr,address owner) public view returns(uint256){
        return Token(tokenAddr).allowance(owner,address(this));
    }
    
}