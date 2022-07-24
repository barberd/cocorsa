
# RSA For Color Computer

## Description

This is a program for the Tandy / Radio-Shack TRS-80 Color Computer to perform RSA key generation, encryption, and decryption. The code is all written in 6809 assembly. It will operate with up to 2048 bit keys.

The Color Computer was an 8 bit computer sold from 1980 through 1991. For more information about the Color Computer, see https://en.wikipedia.org/wiki/TRS-80_Color_Computer and https://www.cocopedia.com/wiki/index.php/Main_Page.

## Source

Code maintained at https://github.com/barberd/cocorsa


## Screenshots

![Startup and Main Menu](screenshots/cocorsa-screenshot1.png?raw=true)


![Key Generation](screenshots/cocorsa-screenshot2.png?raw=true)


## WARNING

While I'm proud of the job I did here, its generally a horrible idea to implement your own cryptography, and this implementation of RSA has not been vetted by community/peer review. Please don't use it for anything serious.

## Why ?

Why create a RSA program for the Color Computer?

When I was a kid I had a CoCo3; I learned BASIC on it. I always told myself I'd learn to program it properly with 'Machine Language' one day. 

I did learn x86 assembly back in college and have picked up some other chipsets like ARM and 68k since then. But I always had a soft spot in my heart for the CoCo. So, 30 years later, I figured it was about time to actually do something non-trivial on it and its 6809 chip. Not sure how I got it in my head to implement RSA, but it was a decent challenge and seemed to fit the bill.

The first challenge was managing multi-byte algorithms. Leventhal has some examples in his book (see the src/leventhal directory), but I needed to also write new subroutines for modular exponentiation and GCD to do RSA. I needed to generate the keys too, so that required diving into random number generation and testing for primality with the Miller-Rabin method. After getting generation, encryption, and decryption working I moved on to doing it more efficiently, dusting off those computer science skills, such as implementing Karatsuba for multiplication, the LTR method for modular exponentiation, and a modulus (remainder) function thats slightly faster since it doesn't need to retain the quotient.

I originally made the false assumption that the CoCo disk controller ROM would have user subroutines for loading and saving files, much like the original 1984 Mac ROMs. But this is not the case. One can do a crazy hack to patch into the disk basic routines (and major props to those programmers who do this), but I found this to be very brittle and any error (like a mistyped filename) will dump the user back into disk basic unless one also patches all the basic error handlers. So, in order to save and load the key and data files, I wrote my own disk IO routines for implementing the CoCo floppy filesystem. This may be the most useful portion for other CoCo developers; find it in src/sub/DSKIO.s. It provides an interface that should be somewhat familiar to those who've done file access with UNIX libc / Linux glibc-type functions.

One may notice my assembly programming got better as things went along. When I look in some older sections I see plenty of room for improvements...pull requests welcome.

But, I did focus on implementing more efficient algorithms where I could. For example, the Chinese Remainer Theorem method of decryption, using Karatsuba for multiplication, and Miller-Rabin for primality testing. As such, I'm somewhat confident saying this is just about as fast as a CoCo can get doing RSA. Which is not that fast at all (the CPU is only .89 mhz / 1.79 mhz on the Coco3) - see the Execution Time section below.

Note the multiple-precision byte arrays are least-significant-byte first. This is simply because thats how Leventhal did it in his book (see the src/leventhal directory), and I extended my algorithm implementations from his examples.

## Executables

RSA.BIN is a RSA key generator and will encrypt and decrypt messages.

It will generate primes using a pseudorandom number generator using user keyboard input delays to provide better randomness and the Miller-Rabin primality test, then calculates the appropriate parts of the public and private keys. The keys are saved on disk, defaulting to PUBKEY.DER and PRIVKEY.DER. It then provides the option to encrypt a message, encrypt a file, or decrypt a file. For the latter, it allows displaying the decrypted message (useful for text) or saving it to disk (useful for binary data). There is also an option to load a public or private key from disk into memory. One can also copy the private key in memory to the public key in memory; do this if you want to send a message to yourself.

TST\*.BIN, are small stub programs just to test out various subroutines as I debugged the algorithm implementations. Build these programs with 'make tests'.

## Implementation Notes

Multiplication uses the Karatsuba Algorithm

Division and Modulus uses naive shift-and-subtract.

Pseudo-random number generator uses a linear congruential generator (see below in improvement ideas).

Prime Generation uses a lookup table for small values and the Miller-Rabin test for larger values when testing for primality.

Greatest Common Divisor and Modular Multiplicative Inverse (used when generating the private key) uses the Euclidean algorithm.

Modular Exponentiation uses left-to-right method (used for encryption and decryption).

RSA Decryption uses the Chinese Remainder Theorem to speed up decryption.

Some subroutines from Leventhal have been modified to either use null-terminated (C-style) strings instead of the original leading-size (Pascal-style) strings, or to allow for over 255 bytelength multi-byte numbers; see the src/leventhal directory.
The disk routines are a new implementation written for this program; it provides a UNIX-ish fopen(), fwrite(), fread(), fseek(), ftell(), fstat(), and fclose() type interface for the CoCo.

This program only implements pure RSA. It does not do message padding, block-chaining, or symmetric encryption. As such, it only encrypts up to the size of the key, and the message is padded with null bytes if shorter (0x00).

## Use

Write the rsa.dsk image to a floppy disk (see https://nitros9.sourceforge.io/wiki/index.php/Transferring_DSK_Images_to_Floppies), load it into your Color Computer emulator, mount it with Drivewire, or copy it to your SD card for use with the CocoSDC. 

If you have a CoCo3 and a monitor that can handle 80-column text, optionally enter 'WIDTH80' first before execution.

Once the disk is loaded into your Coco, load the executable with 

    LOADM"RSA" <enter>

and then execute it with 

    EXEC <enter>.

### Online Emulator

If you want to try this out but don't have a Color Computer or an emulator set up, download the rsa.dsk file and then use the XRoar online emulator at https://www.6809.org.uk/xroar/online/. Change the 'Machine' to a Coco 3, insert your downloaded rsa.dsk into drive 1, then do a hard reset. 

## Outputs

The key generation routine outputs a private and public key file in DER format, with default filenames PRIVKEY.DER and PUBKEY.DER, respectively. These files can be read by other RSA tools such as OpenSSL. For example:

    openssl rsa -in PRIVKEY.DER -inform DER -noout -text

The program can also save encrypted and decrypted messages to a new file.

## Execution Time

### Key Generation
Generating smaller keys like 32 bits can be done in only seconds or minutes, but aren't very useful. On average, generating a 1024 bit key takes about 8 days on a Color Computer 3, and a 2048 bit key takes about a month...but could take twice as long if one gets unlucky. The reason for this is that the distribution of prime numbers is less frequent for higher ranges, so more numbers needed to be tested to find one for larger keys. Larger numbers also take longer to test for primality.

Conceptually key generation would take about twice as long on a CoCo 1 or Coco 2, as these machines do not have the speed poke to double the CPU clock speed.

If one wants to use larger keys and doesn't want to wait to generate one on the CoCo, one can generate it using another RSA tool on a modern PC and load it onto the disk image. For example:

    openssl genrsa -out privkey.pem 2048
    openssl rsa -in privkey.pem -out privkey.der -outform der
    decb copy privkey.der rsa.dsk,PRIVKEY.DER

### Encryption

Encryption is relatively fast, with 2048-bit messages only taking a few minutes to encrypt due to the small public exponent. 

### Decryption

The program uses the 'Chinese Remainer Theorem' method to speed up decryption compared to original RSA.

However, decryption still takes noticeably longer than encryption as the private exponents are very large compared to the public exponent. Messages encrypted with 2048-bit keys takes over a day to decrypt on an original CoCo.

## Building

I used lwtools (http://www.lwtools.ca/) for my assembler and toolshed (https://sourceforge.net/projects/toolshed/) for manipulating disk images. There is a Makefile to help build using gnu make. Install these three packages to build the software.

Run 'make' to build RSA.BIN and generate a rsa.dsk disk image.

Run 'make tests' to build RSA.BIN and several test programs and generate a rsa.dsk disk image. The test programs aren't particularly useful on their own, but might be useful as a testing method if you are looking to modify or debug any of the subroutines.

## Improvement Ideas

Conceptually the arithmetic subroutine codes could handle up to 2^16 bytelength numbers but numbers this size would overflow the stack. On a Color Computer 3, one could implement memory paging to work with larger numbers. Such would require either careful management of the IO (screen and disk) routines page locations in memory when doing IO (such as outputting the '.' and '+' during prime generation) or writing of new custom IO routines that don't rely on the original ROM. However, as generating primes this large would take months or years on the CoCo, the challenge seems rather academic, so the author has not chosen to implement this.

The random number generator is an old school linear congruential generator that on its own is not appropriate for cryptographic use. This is why user input is taken to make it more random. Perhaps it can be replaced with one that is cryptographically secure, such as a xorshift algorithm. See https://en.wikipedia.org/wiki/Cryptographically_secure_pseudorandom_number_generator. Or maybe just TinyMT, see https://en.wikipedia.org/wiki/Mersenne_Twister#TinyMT.

Someone may choose to extend this into a full-blown encryption suite, supporting block-chaining (such as CBC, to allow for encrypting messages longer than the key), symmetric encryption (such as AES, to allow for faster encryption of files larger than the key when combined with block-chaining), and message padding (such as OAEP, to allow for messages shorter than the key and making some attacks harder). However, fitting all this into memory on a CoCo would be difficult, requiring some creative coordination to swap out segments to and from disk as needed.

