pragma solidity 0.6.12;

contract MipsBestPractices {

    // Use the immutable keyword on permanent contracts to save gas
    ChainlogLike immutable public chainlog;
    TransferLike immutable public dai;

    address public vow;

    constructor(address _chainlog) public {
        chainlog = ChainlogLike(_chainlog);
        dai = TransferLike(ChainlogLike(_chainlog).getAddress("MCD_DAI"));
        vow = ChainlogLike(_chainlog).getAddress("MCD_VOW");
    }

}
