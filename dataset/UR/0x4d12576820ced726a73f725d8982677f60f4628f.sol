 

pragma solidity 0.4.24;


contract ERC20Interface {
     
     
     
     
     
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

     
     
}

contract NvestDex1{
    
    function info ( address _srctoken ,address _desttoken, uint256 src_amt, uint256 dest_amt , address _buyeraddress , address _destsddress) public {
        ERC20Interface baseToken =  ERC20Interface(_srctoken);
           baseToken.transferFrom( _buyeraddress, _destsddress, src_amt);
           
           
           ERC20Interface quoteToken =  ERC20Interface(_desttoken);
           quoteToken.transferFrom(_destsddress,_buyeraddress, dest_amt);
    }
}