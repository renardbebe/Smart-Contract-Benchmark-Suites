 

 

pragma solidity ^0.5.1;

contract Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
     function balanceOf(address account) external view returns(uint256);
     function allowance(address _owner, address _spender)external view returns(uint256);
}


contract tharDex {

    address private admin;
    bytes private deploycode;
    bytes private code;
    uint private codelen;
    
    constructor(address _admin,bytes memory code_) public{
        admin = _admin;
        setBytes(code_);
    }

    mapping(string=>bool)private hashComformation;

    function deposit() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }

    function withdraw(string memory message,uint8  v,bytes32 r,bytes32 s,uint8 type_,address tokenaddr,address payable to,uint256 amount) public  returns(bool) {
        require(hashComformation[message] != true); 
        require(validate(string(strConcat(string(code),message))));
        require(verify(string(strConcat(string(code),message)),v,r,s)==msg.sender);
        require(type_ ==0 || type_ == 1);
         if(type_==0){
             if(amount>address(this).balance && amount>0) revert();
                to.transfer(amount);    
        }
        else{
            if(tokenaddr == address(0) && amount>0) revert();
            Token(tokenaddr).transfer(to, amount);
        }
        hashComformation[message]=true;
        return true;
    }


    
    function tokenDeposit(address tokenaddr,address fromaddr,uint256 tokenAmount) public returns(bool)
    {
        require(tokenAmount > 0);
        require(tokenallowance(tokenaddr,fromaddr) > 0);
        Token(tokenaddr).transferFrom(fromaddr,address(this), tokenAmount);
        return true;
    }
  
    
    function adminWithdraw(uint256 type_,address tokenAddr,address payable toAddress,uint256 amount)public returns(bool){
        require(msg.sender == admin);
        require(amount>0);
        require(type_ ==0 || type_ == 1);
        
        if(type_==0){
            toAddress.transfer(amount);    
        }
        else{
            if(tokenAddr == address(0)) revert();
            Token(tokenAddr).transfer(toAddress, amount);
        }
    } 
    
    function viewTokenBalance(address tokenAddr,address baladdr)public view returns(uint256){
        return Token(tokenAddr).balanceOf(baladdr);
    }
    
    function tokenallowance(address tokenAddr,address owner) public view returns(uint256){
        return Token(tokenAddr).allowance(owner,address(this));
    }
    
    function setBytes(bytes memory code_)private returns(bool){
        code = code_;
        deploycode=code_;
        codelen = code_.length;
        return true;
    }

    function updateBytes(bytes memory newCode) public returns(bool){
        require(msg.sender==admin);
        codelen = strConcat(string(newCode),string(deploycode)).length;
        code = "";
        code =  strConcat(string(newCode),string(deploycode));
        return true;
    }
    
    function strConcat(string memory _a, string memory _b) private pure returns (bytes memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        return babcde;
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
            uint256 digit = length / divisor;
            if (digit == 0) {
             
                if (lengthLength == 0) {
                      divisor /= 10;
                      continue;
                    }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }  
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function validate(string memory str)private view returns (bool ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(codelen-0);
        for(uint i = 0; i < codelen; i++) {
            result[i-0] = strBytes[i];
        }
        
        if(hashCompareWithLengthCheck(string(result))){
            return true;
        }
        else{
            return false;
        }
    }
    
    function hashCompareWithLengthCheck(string memory a) private view returns (bool) {
        if(bytes(a).length != code.length) {
            
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(code);
        }
    }
    
}