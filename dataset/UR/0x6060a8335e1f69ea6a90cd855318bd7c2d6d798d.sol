 

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
    using SafeMath for uint;
    event DepositandWithdraw(address from,address tokenAddress,uint256 amount,uint256 type_);  
    
    address payable private admin;  
    address private feeAddress;
    address public feeTokenAddress;
    uint256 public feeAmount;
    bool public dexStatus;    
    
     
    
    bool public feeTokenStatus;
      
    struct orders{  
        address userAddress;
        address tokenAddress;
        uint8 status;
        uint128 type_;
        uint128 price;
        uint128 quantity;
        uint128 tradeQuantity;
    }
    


    struct tokens{  
        address tokenAddress;
        string tokenSymbol;
        uint128 decimals;
        uint120 withdrawFee;
        uint8 status;
    }
    
   
    
    constructor(address payable _admin,address feeAddress_,address feetokenaddress_,uint128 minFeeamount,bool _status) public{ 
        admin = _admin;
        feeAddress = feeAddress_;
        dexStatus = true;  
        feeTokenAddress = feetokenaddress_;
        feeAmount = minFeeamount;
        feeTokenStatus = _status;
    }

    
    mapping(uint256=>orders) public Order;  
    
    mapping(address=>mapping(address=>uint256))public userDetails;   
    
    mapping(address=>uint256) public withdrawfee;  
     
     mapping(address=>tokens) public tokendetails;  
     
     mapping(address=>bool) public user_status;  
     
     mapping(uint256=>bool)public tradeOrders;  
     
     mapping(address=>mapping(address=>uint256))public adminProfit;  
    
    modifier dexstatuscheck(){  
       require(dexStatus==true);
       _;
    }
    
    modifier onlyFeeAddress(){
        require(msg.sender == feeAddress);
       _;
    }
    
    modifier onlyOwner(){
    require(msg.sender == admin);
      _;
    }
    
    function setDexStatus(bool status_) onlyOwner public returns(bool){  
        dexStatus = status_;  
        return true;
    }   
    
    function changeFeeAddress(address changeFeeaddress) onlyOwner public returns(bool){
        feeAddress = changeFeeaddress;
        return true;
    }
    
    function changeAdmin(address payable changeAdminaddress) onlyOwner public returns(bool){
        admin = changeAdminaddress;
        return true;
    }
 
    function setFeeToken(address feeTokenaddress,uint128 min_fee_amount,bool _status) onlyOwner public returns(bool){
        feeTokenAddress = feeTokenaddress;
        feeAmount = min_fee_amount;
        feeTokenStatus = _status;
        return true;
    }

    function addToken(address tokenAddress_,string memory tokenSymbol,uint128 decimal_,uint120 withdrawFee_) onlyFeeAddress public returns(bool){
        require(tokendetails[tokenAddress_].status==0);  
        tokendetails[tokenAddress_].tokenAddress=tokenAddress_;
        tokendetails[tokenAddress_].tokenSymbol=tokenSymbol;  
        tokendetails[tokenAddress_].decimals=decimal_;  
        tokendetails[tokenAddress_].withdrawFee = withdrawFee_;   
        tokendetails[tokenAddress_].status=1;  
        return true;
    }
    
     
    function deposit() dexstatuscheck public payable returns(bool) { 
        require(msg.sender!= admin);
        require(msg.value > 0); 
        userDetails[msg.sender][address(0)]=userDetails[msg.sender][address(0)].add(msg.value);
        user_status[msg.sender]=true; 
        emit DepositandWithdraw( msg.sender, address(0),msg.value,0);
        return true;
    }
    
    function tokenDeposit(address tokenaddr,uint256 tokenAmount) dexstatuscheck public returns(bool)
    {
        require(msg.sender!= admin);
        require(tokenAmount > 0 && tokendetails[tokenaddr].status==1);  
        require(tokenallowance(tokenaddr,msg.sender,address(this)) > 0);  
        userDetails[msg.sender][tokenaddr] = userDetails[msg.sender][tokenaddr].add(tokenAmount);
        Token(tokenaddr).transferFrom(msg.sender,address(this), tokenAmount);
        user_status[msg.sender]=true; 
        emit DepositandWithdraw( msg.sender,tokenaddr,tokenAmount,0);
        return true;
        
    }
  
   
  
    function withdraw(uint8 type_,address tokenaddr,uint256 amount) dexstatuscheck public returns(bool) {
        require(msg.sender!= admin);
        require(type_ ==0 || type_ == 1);  
         if(type_==0){  
         require(tokenaddr == address(0));  
         require(amount>0 && amount <= userDetails[msg.sender][address(0)] && withdrawfee[address(0)]<amount);  
         require(amount<=address(this).balance);
                msg.sender.transfer(amount.sub(withdrawfee[address(0)]));    
                userDetails[msg.sender][address(0)] = userDetails[msg.sender][address(0)].sub(amount);  
                adminProfit[admin][address(0)] = adminProfit[admin][address(0)].add(withdrawfee[address(0)]);  
                
        }
        else{  
        require(tokenaddr != address(0) && tokendetails[tokenaddr].status==1);    
        require(amount>0 && amount <= userDetails[msg.sender][tokenaddr] && withdrawfee[tokenaddr]<amount);
              Token(tokenaddr).transfer(msg.sender, (amount.sub(withdrawfee[tokenaddr]))); 
              userDetails[msg.sender][tokenaddr] = userDetails[msg.sender][tokenaddr].sub(amount);   
              adminProfit[admin][tokenaddr] = adminProfit[admin][tokenaddr].add(withdrawfee[tokenaddr]);  
        }
        emit DepositandWithdraw( msg.sender,tokenaddr,amount,1);
        return true;
    }
    
     
     function adminProfitWithdraw(uint8 type_,address tokenAddr)public returns(bool){  
       require(msg.sender == admin);  
       require(type_ ==0 || type_ == 1);
         if(type_==0){  
            admin.transfer(adminProfit[admin][address(0)]);  
            adminProfit[admin][address(0)]=0;  
                
        }
        else{  
            require(tokenAddr != address(0)) ;
            Token(tokenAddr).transfer(admin, adminProfit[admin][tokenAddr]);  
            adminProfit[admin][tokenAddr]=0; 
        }
            return true;
        }
        
        
    function setwithdrawfee(address[] memory addr,uint120[] memory feeamount)public returns(bool)   
        {
          require(msg.sender==admin);
           
          require(addr.length <10 && feeamount.length < 10 && addr.length==feeamount.length);
          for(uint8 i=0;i<addr.length;i++){
                withdrawfee[addr[i]]=feeamount[i];   
                tokendetails[addr[i]].withdrawFee = feeamount[i];    
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
    
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }
 
    function addressToString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
 
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
 
     
       
       
       
       
       
       
       
  
     
       
       
       
       
       
       
       
       
  
     
       
       
       
       
    function makeOrder(uint128[7] memory makerOrder, uint128[7] memory takerOrder,address[4] memory tradeAddress,uint8[2] memory  v,bytes32[4] memory rs) onlyFeeAddress public returns(bool){
        require(tradeOrders[makerOrder[0]]!=true && tradeOrders[takerOrder[0]] !=true);
        require(makerOrder[4]>=block.timestamp && takerOrder[4]>=block.timestamp);   
        uint256 amount__m;
        uint256 amount__t;
        makerOrder[6]=0;
        takerOrder[6]=0;
        
        
        if(Order[makerOrder[0]].status ==0){  
             
            if(tradeAddress[2]==feeTokenAddress){
                (feeTokenStatus) ? makerOrder[6]=1 : makerOrder[6]=0;
            }
            else{
                require(userDetails[tradeAddress[1]][feeTokenAddress]>=feeAmount);    
                makerOrder[6]=1;
                if(tradeAddress[0] == feeTokenAddress ){
                  amount__m =amount__m.add(feeAmount);
                }
            }
             
            require(verify(strConcat(uint2str(makerOrder[0]),addressToString(tradeAddress[0]),uint2str(makerOrder[2]),uint2str(makerOrder[1]),uint2str(makerOrder[4])),v[0],rs[0],rs[1])==tradeAddress[1]);
            makerOrder[5] = makerOrder[1];
        }
        else{
            require(Order[makerOrder[0]].tradeQuantity > 0);
           
            makerOrder[2] = Order[makerOrder[0]].price;
            makerOrder[3] = Order[makerOrder[0]].type_;
            makerOrder[5] = Order[makerOrder[0]].tradeQuantity;
            tradeAddress[0] = Order[makerOrder[0]].tokenAddress;
            tradeAddress[1] = Order[makerOrder[0]].userAddress;
        }

        if(Order[takerOrder[0]].status ==0){   
             
            if(tradeAddress[0]==feeTokenAddress){
                (feeTokenStatus) ? takerOrder[6]=1 : takerOrder[6]=0;
            }
            else{
                 
                require(userDetails[tradeAddress[3]][feeTokenAddress]>=feeAmount);      
                takerOrder[6]=1;
                
                if(tradeAddress[2] == feeTokenAddress){
                    amount__t =amount__t.add(feeAmount);
                }
            }
             
            require(verify(strConcat(uint2str(takerOrder[0]),addressToString(tradeAddress[2]),uint2str(takerOrder[2]),uint2str(takerOrder[1]),uint2str(takerOrder[4])),v[1],rs[2],rs[3])==tradeAddress[3]);
            takerOrder[5] = takerOrder[1];
        }
        else{
            require(Order[takerOrder[0]].tradeQuantity > 0);
            takerOrder[2] = Order[takerOrder[0]].price;
            takerOrder[3] = Order[takerOrder[0]].type_;
            takerOrder[5] = Order[takerOrder[0]].tradeQuantity;
            tradeAddress[2] = Order[takerOrder[0]].tokenAddress;
            tradeAddress[3] = Order[takerOrder[0]].userAddress;
        }

        uint128 tradeAmount;

        if(takerOrder[5] > makerOrder[5]){
            tradeAmount = makerOrder[5];
        }
        else{
            tradeAmount = takerOrder[5];
        }
        
         
        if(makerOrder[3] == 1){ 
            amount__m =amount__m.add(((tradeAmount)*(makerOrder[2]))/tokendetails[tradeAddress[0]].decimals) ;  
            amount__t =amount__t.add(tradeAmount);   
        }
        else{     
            amount__m = amount__m.add(tradeAmount);  
            amount__t = amount__t.add(tradeAmount*(makerOrder[2])/ tokendetails[tradeAddress[2]].decimals);  
        }
        
        if(userDetails[tradeAddress[1]][tradeAddress[0]]<amount__m){   
            return false;
        }
        
        if(userDetails[tradeAddress[3]][tradeAddress[2]]<amount__t){  
            return false;
        }

        if(takerOrder[5] > makerOrder[5]){
            if(Order[takerOrder[0]].status!=1){
                Order[takerOrder[0]].userAddress = tradeAddress[3];
                Order[takerOrder[0]].type_ = takerOrder[3];
                Order[takerOrder[0]].price = takerOrder[2];
                Order[takerOrder[0]].quantity  = takerOrder[1];
                Order[takerOrder[0]].tradeQuantity  = takerOrder[5];
                Order[takerOrder[0]].tokenAddress = tradeAddress[2];
                Order[takerOrder[0]].status=1;  
            }
            Order[takerOrder[0]].tradeQuantity -=tradeAmount; 
            Order[makerOrder[0]].tradeQuantity=0;
            tradeOrders[makerOrder[0]] = true;
        }
        else if(takerOrder[5] < makerOrder[5]){
            if(Order[makerOrder[0]].status!=1  ){
                Order[makerOrder[0]].userAddress = tradeAddress[1];
                Order[makerOrder[0]].type_ = makerOrder[3];
                Order[makerOrder[0]].price = makerOrder[2];
                Order[makerOrder[0]].quantity  = makerOrder[1];
                Order[makerOrder[0]].tradeQuantity  =  makerOrder[5];
                Order[makerOrder[0]].tokenAddress = tradeAddress[0];
                Order[makerOrder[0]].status=1;  
             }
            Order[makerOrder[0]].tradeQuantity -=tradeAmount;
            Order[takerOrder[0]].tradeQuantity=0;
            tradeOrders[takerOrder[0]] = true;
        }
        else{
            Order[makerOrder[0]].tradeQuantity=0;
            Order[takerOrder[0]].tradeQuantity=0;
            tradeOrders[makerOrder[0]] = true;
            tradeOrders[takerOrder[0]] = true;
        }
         
        makerOrder[5] = uint128(amount__t); 
         
        takerOrder[5] = uint128(amount__m);
                    
        if(makerOrder[6]==1 ){
             
             
            if(tradeAddress[0] == feeTokenAddress){
                amount__m = amount__m.sub(feeAmount);
                takerOrder[5]=sub128(takerOrder[5],uint128(feeAmount));
                 
                userDetails[tradeAddress[1]][feeTokenAddress] =userDetails[tradeAddress[1]][feeTokenAddress].sub(feeAmount);
                 
                adminProfit[admin][feeTokenAddress] =adminProfit[admin][feeTokenAddress].add(feeAmount);
            }
             
            else if(tradeAddress[2] == feeTokenAddress){
                 
                if(makerOrder[5]>=feeAmount){
                    makerOrder[5] = sub128(makerOrder[5],uint128(feeAmount));
                    adminProfit[admin][feeTokenAddress] = adminProfit[admin][feeTokenAddress].add(feeAmount);     
                }
                 
                 
                 
                else{
                    adminProfit[admin][feeTokenAddress] = adminProfit[admin][feeTokenAddress].add(makerOrder[5]);
                     
                    makerOrder[5] = 0;
                }
            }
             
            else{
                userDetails[tradeAddress[1]][feeTokenAddress] =userDetails[tradeAddress[1]][feeTokenAddress].sub(feeAmount);
                adminProfit[admin][feeTokenAddress] =adminProfit[admin][feeTokenAddress].add(feeAmount);
            }
        }
            
        if(takerOrder[6]==1){
             
             
            if(tradeAddress[2] == feeTokenAddress){
                amount__t = amount__t.sub(feeAmount);
                makerOrder[5] =sub128(makerOrder[5],uint128(feeAmount));
                 
                userDetails[tradeAddress[3]][feeTokenAddress] = userDetails[tradeAddress[3]][feeTokenAddress].sub(feeAmount);
                 
                adminProfit[admin][feeTokenAddress] =adminProfit[admin][feeTokenAddress].add(feeAmount);  
            }
             
            else if(tradeAddress[0] == feeTokenAddress){
                 
                 
              
                 
                if(takerOrder[5]>=feeAmount){
                    takerOrder[5] = sub128(takerOrder[5],uint128(feeAmount));
                    adminProfit[admin][feeTokenAddress] = adminProfit[admin][feeTokenAddress].add(feeAmount);     
                }
                 
                 
                 
                else{
                    adminProfit[admin][feeTokenAddress] =adminProfit[admin][feeTokenAddress].add(takerOrder[5]);        
                    takerOrder[5]=0;
                }
                
            }
             
            else{
                userDetails[tradeAddress[3]][feeTokenAddress] = userDetails[tradeAddress[3]][feeTokenAddress].sub(feeAmount);
                adminProfit[admin][feeTokenAddress] =adminProfit[admin][feeTokenAddress].add(feeAmount);   
            }
        }
                    
         
        userDetails[tradeAddress[1]][tradeAddress[0]] = userDetails[tradeAddress[1]][tradeAddress[0]].sub(amount__m);    
        userDetails[tradeAddress[3]][tradeAddress[2]] = userDetails[tradeAddress[3]][tradeAddress[2]].sub(amount__t);    
        
         
        userDetails[tradeAddress[1]][tradeAddress[2]] = userDetails[tradeAddress[1]][tradeAddress[2]].add(makerOrder[5]);  
        userDetails[tradeAddress[3]][tradeAddress[0]] = userDetails[tradeAddress[3]][tradeAddress[0]].add(takerOrder[5]);  
        
        return true;
    }
    
    function sub128(uint128 a, uint128 b) internal pure  returns (uint128) {
        assert(b <= a);
        return a - b;
    }
    
     function viewTokenBalance(address tokenAddr,address baladdr)public view returns(uint256){  
        return Token(tokenAddr).balanceOf(baladdr);
    }
    
    function tokenallowance(address tokenAddr,address owner,address _spender) public view returns(uint256){  
        return Token(tokenAddr).allowance(owner,_spender);
    }
    

}