'use client';

import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from './atoms/sheet';
import type { ReactNode } from 'react';
import { Button } from './atoms/button';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  description?: string;
  children: ReactNode;
  footerContent?: ReactNode;
  primaryActionLabel?: string;
  onPrimaryAction?: () => void;
}

export function Modal({
  isOpen,
  onClose,
  title,
  description,
  children,
  footerContent,
  primaryActionLabel = 'Confirm',
  onPrimaryAction,
}: ModalProps) {
  const handlePrimaryAction = () => {
    if (onPrimaryAction) {
      onPrimaryAction();
    } else {
      onClose();
    }
  };

  return (
    <Sheet open={isOpen} onOpenChange={onClose}>
      <SheetContent
        side="right"
        className="sm:max-w-[580px] top-8 bottom-8 right-8 w-[calc(100%-64px)] h-[calc(100%-64px)] rounded-lg overflow-y-auto"
      >
        <SheetHeader>
          <SheetTitle>{title}</SheetTitle>
          {description && (
            <SheetDescription className="text-sm">
              {description}
            </SheetDescription>
          )}
        </SheetHeader>
        <div className="py-4">{children}</div>

        <SheetFooter className='w-full'>
          {footerContent ? (
            footerContent
          ) : (
            <Button variant="purple" size="full" onClick={handlePrimaryAction}>
              {primaryActionLabel}
            </Button>
          )}
        </SheetFooter>
      </SheetContent>
    </Sheet>
  );
}
