 
contract ForTokenTimelock {
    using SafeERC20 for IERC20;

     
    IERC20 private _token = IERC20(0x1FCdcE58959f536621d76f5b7FfB955baa5A672F);

     
    address private _beneficiary = 0xb7A6Fc901ea7Af2B2A25F972958CF92cAfB236Da;

     
    uint256 private _firstReleaseDate = now + 55 days;
    uint256 private _secondReleaseDate = now + 145 days;
    bool _isFirstClaimAlready = false;

     
    function release() public {
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "ForTokenTimelock: no tokens to release");

        if (now >= _firstReleaseDate && _isFirstClaimAlready == false) {
            _token.safeTransfer(_beneficiary, amount/2);
            _isFirstClaimAlready = true;
        } else if (now >= _secondReleaseDate){
            _token.safeTransfer(_beneficiary, amount);
        }
    }
}
