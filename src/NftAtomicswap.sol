//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftAtomicSwap {


    enum PaymentState {
        Uninitialized,
        PaymentSent,
        ReceiverSpent,
        SenderRefunded
    }

    struct Payment {
        bytes20 paymentHash;
        uint64 lockTime;
        PaymentState state;
        address tokenAddress;
        uint256 tokenId;
    }

    mapping (bytes32 => Payment) public payments;

    event PaymentSent(bytes32 id);
    event ReceiverSpent(bytes32 id, bytes32 secret);
    event SenderRefunded(bytes32 id);

    function depositNFT(
    bytes32 _id,
    address _nftAddress,
    uint256 _tokenId,
    address _receiver,
    bytes20 _secretHash,
    uint64 _lockTime
) external {
    require(_nftAddress != address(0), "Invalid NFT address");
    require(_receiver != address(0), "Invalid receiver address");
    require(payments[_id].state == PaymentState.Uninitialized, "Payment already initialized");

    IERC721 nft = IERC721(_nftAddress);
    require(nft.ownerOf(_tokenId) == msg.sender, "Sender does not own the NFT");
    require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), 
            "Contract not approved to transfer NFT");

    bytes20 paymentHash = ripemd160(abi.encodePacked(
        _receiver,
        msg.sender,
        _secretHash,
        _nftAddress,
        _tokenId
    ));

    payments[_id] = Payment(
        paymentHash,
        _lockTime,
        PaymentState.PaymentSent,
        _nftAddress,
        _tokenId
    );

    nft.transferFrom(msg.sender, address(this), _tokenId);
    emit PaymentSent(_id);
}



    function completeNFTSwap(
    bytes32 _id,
    bytes32 _secret,
    address _nftAddress,
    uint256 _tokenId,
    address _sender
) external {
    require(_nftAddress != address(0), "Invalid NFT address");
    require(payments[_id].state == PaymentState.PaymentSent, "Payment not initiated or already completed");

    bytes20 paymentHash = ripemd160(abi.encodePacked(
        msg.sender, 
        _sender,
        ripemd160(abi.encodePacked(sha256(abi.encodePacked(_secret)))),
        _nftAddress,
        _tokenId
    ));

    require(paymentHash == payments[_id].paymentHash, "Invalid secret or payment details");

    payments[_id].state = PaymentState.ReceiverSpent;

    IERC721 nft = IERC721(_nftAddress);
    nft.transferFrom(address(this), msg.sender, _tokenId);

    emit ReceiverSpent(_id, _secret);
}


function refundNFT(
    bytes32 _id,
    address _nftAddress,
    uint256 _tokenId
) external {
    require(_nftAddress != address(0), "Invalid NFT address");
    require(payments[_id].state == PaymentState.PaymentSent, "Payment not in correct state");
    require(block.timestamp > payments[_id].lockTime, "Lock time has not expired");

    payments[_id].state = PaymentState.SenderRefunded;

    IERC721 nft = IERC721(_nftAddress);
    nft.transferFrom(address(this), msg.sender, _tokenId);

    emit SenderRefunded(_id);
}
    

}