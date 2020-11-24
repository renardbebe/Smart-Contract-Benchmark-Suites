 

pragma solidity 0.4.24;

 

interface VaultI {
    function deposit(address contributor) external payable;
    function saleSuccessful() external;
    function enableRefunds() external;
    function refund(address contributor) external;
    function close() external;
    function sendFundsToWallet() external;
}

 

 
contract Refunder {

     
     
     
     
     
     
    function refundContribution(VaultI _vault, address[] _contributors)
        external
    {
        for (uint256 i = 0; i < _contributors.length; i++) {
            address contributor = _contributors[i];
            _vault.refund(contributor);
        }
    }
}